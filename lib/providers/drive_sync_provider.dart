import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../models/backup_payload.dart';
import '../services/drive_sync/drive_auth_source.dart';
import '../services/drive_sync/bearer_token_client.dart';
import '../services/drive_sync/google_sign_in_auth_source.dart';
import 'last_mutation_provider.dart';
import 'shared_preferences_provider.dart';

final driveSyncControllerProvider =
    NotifierProvider<DriveSyncController, DriveSyncState>(
      DriveSyncController.new,
    );

enum DriveSyncStatus { signedOut, idle, syncing, synced, error }

class DriveSyncState {
  const DriveSyncState({
    required this.status,
    this.accountEmail,
    this.lastSyncedAt,
    this.message,
  });

  const DriveSyncState.signedOut()
    : status = DriveSyncStatus.signedOut,
      accountEmail = null,
      lastSyncedAt = null,
      message = null;

  final DriveSyncStatus status;
  final String? accountEmail;
  final DateTime? lastSyncedAt;
  final String? message;

  bool get isSyncing => status == DriveSyncStatus.syncing;
}

class DriveSyncException implements Exception {
  const DriveSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DriveSyncController extends Notifier<DriveSyncState> {
  static const _lastSyncedAtKey = 'driveLastSyncedAt';
  static const _backupFileName = 'expenses_backup.json';
  static const _syncDebounce = Duration(seconds: 8);
  static const _futureClockTolerance = Duration(hours: 6);

  late final DriveAuthSource _authSource;
  Timer? _debounceTimer;

  @override
  DriveSyncState build() {
    _authSource = _buildAuthSource();
    final emailSubscription = _authSource.accountEmailChanges.listen(
      _handleEmailChange,
    );
    ref.onDispose(() {
      emailSubscription.cancel();
      _debounceTimer?.cancel();
    });

    // Real local edits (not ones caused by applying a pulled payload —
    // BackupPayload.applyToProviders sets this exactly rather than
    // touching it) schedule a debounced push/pull.
    ref.listen<DateTime>(lastMutationProvider, (previous, next) {
      if (previous != null && previous != next) {
        _scheduleDebouncedSync();
      }
    });

    final preferences = ref.read(sharedPreferencesProvider);
    final storedSyncedAt = preferences.getString(_lastSyncedAtKey);
    final lastSyncedAt = storedSyncedAt == null
        ? null
        : DateTime.tryParse(storedSyncedAt);

    return DriveSyncState(
      status: DriveSyncStatus.signedOut,
      lastSyncedAt: lastSyncedAt,
    );
  }

  DriveAuthSource _buildAuthSource() {
    // Guard with kIsWeb first — dart:io's Platform isn't usable on web.
    if (!kIsWeb && Platform.isWindows) {
      // Replaced by a real OAuth loopback flow once that's built; until
      // then Windows just stays signed out rather than crashing.
      return _UnsupportedAuthSource(
        "Google Drive sync on Windows isn't available yet.",
      );
    }

    return GoogleSignInAuthSource();
  }

  void _handleEmailChange(String? email) {
    if (email == null) {
      state = DriveSyncState(
        status: DriveSyncStatus.signedOut,
        lastSyncedAt: state.lastSyncedAt,
      );
      return;
    }

    state = DriveSyncState(
      status: state.status == DriveSyncStatus.signedOut
          ? DriveSyncStatus.idle
          : state.status,
      accountEmail: email,
      lastSyncedAt: state.lastSyncedAt,
      message: state.message,
    );
  }

  void _scheduleDebouncedSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_syncDebounce, () {
      unawaited(syncNow());
    });
  }

  Future<void> signIn() async {
    try {
      await _authSource.signIn();
    } catch (e) {
      state = DriveSyncState(
        status: DriveSyncStatus.error,
        accountEmail: state.accountEmail,
        lastSyncedAt: state.lastSyncedAt,
        message: _friendlyMessage(e),
      );
      return;
    }

    await syncNow();
  }

  Future<void> signOut() async {
    await _authSource.signOut();
    state = DriveSyncState(
      status: DriveSyncStatus.signedOut,
      lastSyncedAt: state.lastSyncedAt,
    );
  }

  Future<void> syncOnLaunchIfSignedIn() async {
    await _authSource.ensureInitialized();
    await syncNow();
  }

  Future<void> syncNow() async {
    if (state.status == DriveSyncStatus.syncing) {
      return;
    }

    final token = await _authSource.currentAccessToken();
    if (token == null) {
      if (state.status != DriveSyncStatus.signedOut) {
        state = DriveSyncState(
          status: DriveSyncStatus.signedOut,
          lastSyncedAt: state.lastSyncedAt,
        );
      }
      return;
    }

    state = DriveSyncState(
      status: DriveSyncStatus.syncing,
      accountEmail: state.accountEmail,
      lastSyncedAt: state.lastSyncedAt,
    );

    try {
      final driveApi = driveApiFor(_authSource);
      final list = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName' and trashed = false",
        $fields: 'files(id)',
      );
      final remoteFileId = list.files?.firstOrNull?.id;
      final localPayload = BackupPayload.fromProviders(ref);

      if (remoteFileId == null) {
        // First-ever sync from any device — seed the remote with local
        // state.
        await _push(driveApi, localPayload, fileId: null);
      } else {
        final remoteBytes = await _download(driveApi, remoteFileId);
        final remotePayload = _decodePayload(remoteBytes);
        if (remotePayload == null) {
          throw const DriveSyncException('Remote backup is unreadable.');
        }

        final comparison = _compareUpdatedAt(
          localPayload.updatedAt,
          remotePayload.updatedAt,
        );
        if (comparison > 0) {
          await _push(driveApi, localPayload, fileId: remoteFileId);
        } else if (comparison < 0) {
          remotePayload.applyToProviders(ref);
        }
        // comparison == 0: nothing changed on either side, no-op.
      }

      final now = DateTime.now().toUtc();
      state = DriveSyncState(
        status: DriveSyncStatus.synced,
        accountEmail: state.accountEmail,
        lastSyncedAt: now,
      );
      await _persistLastSyncedAt(now);
    } catch (e) {
      state = DriveSyncState(
        status: DriveSyncStatus.error,
        accountEmail: state.accountEmail,
        lastSyncedAt: state.lastSyncedAt,
        message: _friendlyMessage(e),
      );
    }
  }

  Future<void> _push(
    drive.DriveApi driveApi,
    BackupPayload payload, {
    required String? fileId,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    final media = drive.Media(Stream.value(bytes), bytes.length);

    if (fileId == null) {
      await driveApi.files.create(
        drive.File(name: _backupFileName, parents: ['appDataFolder']),
        uploadMedia: media,
      );
    } else {
      await driveApi.files.update(drive.File(), fileId, uploadMedia: media);
    }
  }

  Future<List<int>> _download(drive.DriveApi driveApi, String fileId) async {
    final media =
        await driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return bytes;
  }

  BackupPayload? _decodePayload(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        return null;
      }
      return BackupPayload.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  /// Compares two `updatedAt` timestamps for last-write-wins, guarding
  /// against a device with a badly wrong clock claiming to be "newer"
  /// than it plausibly could be.
  int _compareUpdatedAt(DateTime local, DateTime remote) {
    return _clampToPlausible(local).compareTo(_clampToPlausible(remote));
  }

  DateTime _clampToPlausible(DateTime timestamp) {
    final cutoff = DateTime.now().toUtc().add(_futureClockTolerance);
    return timestamp.isAfter(cutoff) ? cutoff : timestamp;
  }

  String _friendlyMessage(Object error) {
    if (error is DriveSyncException) {
      return error.message;
    }
    if (error is UnsupportedError) {
      return error.message ?? "This isn't available on this platform yet.";
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _persistLastSyncedAt(DateTime dateTime) async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setString(_lastSyncedAtKey, dateTime.toIso8601String());
  }
}

/// Placeholder for platforms without a real [DriveAuthSource] yet
/// (currently just Windows, until its OAuth loopback flow is built) —
/// stays permanently signed out instead of crashing the app.
class _UnsupportedAuthSource implements DriveAuthSource {
  _UnsupportedAuthSource(this._message);

  final String _message;

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<void> signIn() async {
    throw UnsupportedError(_message);
  }

  @override
  Future<String?> currentAccessToken() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Stream<String?> get accountEmailChanges => const Stream.empty();
}
