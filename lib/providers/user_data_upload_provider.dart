import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/auth/auth_providers.dart';
import 'category_provider.dart';

final userDataUploadRepositoryProvider = Provider<UserDataUploadRepository>((
  ref,
) {
  return UserDataUploadRepository(ref.watch(supabaseClientProvider));
});

final userDataUploadControllerProvider =
    NotifierProvider<UserDataUploadController, UserDataUploadState>(
      UserDataUploadController.new,
    );

enum UserDataUploadStatus { idle, uploading, uploaded, failed, unavailable }

class UserDataUploadState {
  const UserDataUploadState({
    required this.status,
    this.lastUploadedAt,
    this.message,
  });

  const UserDataUploadState.idle()
    : status = UserDataUploadStatus.idle,
      lastUploadedAt = null,
      message = null;

  final UserDataUploadStatus status;
  final DateTime? lastUploadedAt;
  final String? message;

  bool get isUploading => status == UserDataUploadStatus.uploading;
}

class UserDataUploadController extends Notifier<UserDataUploadState> {
  static const _lastSyncKey = 'categoriesLastSyncAt';

  bool _uploadAgainRequested = false;
  bool _loadRequested = false;

  @override
  UserDataUploadState build() {
    _restoreLastSync();
    return const UserDataUploadState.idle();
  }

  Future<void> _restoreLastSync() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_lastSyncKey);
    final lastSync = value == null ? null : DateTime.tryParse(value);
    if (lastSync == null || state.lastUploadedAt != null) {
      return;
    }

    state = UserDataUploadState(
      status: UserDataUploadStatus.uploaded,
      lastUploadedAt: lastSync,
    );
  }

  Future<bool> uploadCurrent() async {
    if (state.isUploading) {
      _uploadAgainRequested = true;
      state = UserDataUploadState(
        status: UserDataUploadStatus.uploading,
        lastUploadedAt: state.lastUploadedAt,
        message: 'Upload queued.',
      );
      return false;
    }

    var uploaded = false;
    state = UserDataUploadState(
      status: UserDataUploadStatus.uploading,
      lastUploadedAt: state.lastUploadedAt,
    );

    try {
      await ref
          .read(userDataUploadRepositoryProvider)
          .upload(categories: ref.read(categoryProvider));

      state = UserDataUploadState(
        status: UserDataUploadStatus.uploaded,
        lastUploadedAt: DateTime.now(),
      );
      await _persistLastSync(state.lastUploadedAt!);
      uploaded = true;
    } on UserDataUploadException catch (error) {
      state = UserDataUploadState(
        status: UserDataUploadStatus.unavailable,
        lastUploadedAt: state.lastUploadedAt,
        message: error.message,
      );
    } on PostgrestException catch (error) {
      state = UserDataUploadState(
        status: UserDataUploadStatus.failed,
        lastUploadedAt: state.lastUploadedAt,
        message: _postgrestErrorMessage(error),
      );
    } catch (_) {
      state = UserDataUploadState(
        status: UserDataUploadStatus.failed,
        lastUploadedAt: state.lastUploadedAt,
        message: 'Upload failed. Please try again.',
      );
    }

    if (_uploadAgainRequested) {
      _uploadAgainRequested = false;
      await uploadCurrent();
    }

    return uploaded;
  }

  Future<bool> loadCurrentIfOnline() async {
    if (_loadRequested ||
        ref.read(supabaseClientProvider).auth.currentUser == null) {
      return false;
    }
    _loadRequested = true;

    try {
      final categories = await ref
          .read(userDataUploadRepositoryProvider)
          .load();
      if (categories.isEmpty) {
        return false;
      }

      ref.read(categoryProvider.notifier).replaceCategories(categories);
      final loadedAt = DateTime.now();
      state = UserDataUploadState(
        status: UserDataUploadStatus.uploaded,
        lastUploadedAt: loadedAt,
      );
      await _persistLastSync(loadedAt);
      return true;
    } on UserDataUploadException {
      return false;
    } on PostgrestException catch (error) {
      state = UserDataUploadState(
        status: UserDataUploadStatus.failed,
        lastUploadedAt: state.lastUploadedAt,
        message: _postgrestErrorMessage(error),
      );
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadCurrentIfOnline() {
    if (ref.read(supabaseClientProvider).auth.currentUser == null) {
      return Future.value(false);
    }

    return uploadCurrent();
  }

  String _postgrestErrorMessage(PostgrestException error) {
    if (error.message.contains('public.categories') ||
        error.message.contains('schema cache')) {
      return 'Cloud table missing. Create public.categories in Supabase.';
    }

    return error.message;
  }

  Future<void> _persistLastSync(DateTime dateTime) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastSyncKey, dateTime.toIso8601String());
  }
}

class UserDataUploadRepository {
  const UserDataUploadRepository(this._client);

  final SupabaseClient _client;

  Future<void> upload({required List<FinancialCategory> categories}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const UserDataUploadException(
        'Sign in with an online account before uploading data.',
      );
    }

    final uploadedAt = DateTime.now().toUtc().toIso8601String();

    await _client.from('categories').upsert({
      'user_id': user.id,
      'categories': categories.map((category) => category.toJson()).toList(),
      'updated_at': uploadedAt,
    }, onConflict: 'user_id');
  }

  Future<List<FinancialCategory>> load() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const UserDataUploadException(
        'Sign in with an online account before syncing categories.',
      );
    }

    final response = await _client
        .from('categories')
        .select('categories')
        .eq('user_id', user.id)
        .maybeSingle();

    final categoriesJson = response?['categories'];
    if (categoriesJson is! List) {
      return const [];
    }

    final categories = <FinancialCategory>[];
    for (final item in categoriesJson) {
      final category = switch (item) {
        final Map<String, dynamic> json => FinancialCategory.fromJson(json),
        final Map json => FinancialCategory.fromJson(
          Map<String, dynamic>.from(json),
        ),
        _ => null,
      };

      if (category != null) {
        categories.add(category);
      }
    }

    return categories;
  }
}

class UserDataUploadException implements Exception {
  const UserDataUploadException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
