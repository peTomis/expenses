import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_preferences_provider.dart';

final lastMutationProvider = NotifierProvider<LastMutationNotifier, DateTime>(
  LastMutationNotifier.new,
);

/// Tracks when the local financial data / categories were last mutated by
/// the user (as opposed to when they were last exported/synced), so a
/// last-write-wins comparison against a remote backup can tell which side
/// actually has newer data.
class LastMutationNotifier extends Notifier<DateTime> {
  static const _key = 'lastMutationAt';

  @override
  DateTime build() {
    final preferences = ref.read(sharedPreferencesProvider);
    final stored = preferences.getString(_key);
    final storedDateTime = stored == null ? null : DateTime.tryParse(stored);
    if (storedDateTime != null) {
      return storedDateTime;
    }

    final hasExistingData =
        preferences.containsKey('financialData') ||
        preferences.containsKey('categories');

    // A device with pre-existing local data but no recorded mutation time
    // (e.g. upgrading from before this provider existed) should look
    // recently-modified, not ancient — otherwise a future sync would treat
    // it as stale and silently overwrite it with whatever is remote.
    return hasExistingData
        ? DateTime.now().toUtc()
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  /// Called by real local edits.
  void touch() => _setState(DateTime.now().toUtc());

  /// Called when applying a pulled/imported payload, so the act of applying
  /// remote data doesn't itself make local look newer than what was just
  /// applied.
  void setExactly(DateTime dateTime) => _setState(dateTime.toUtc());

  void _setState(DateTime dateTime) {
    state = dateTime;
    unawaited(_persist(dateTime));
  }

  Future<void> _persist(DateTime dateTime) async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setString(_key, dateTime.toIso8601String());
  }
}
