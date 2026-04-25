import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final usernameProvider = AsyncNotifierProvider<UsernameNotifier, String?>(
  UsernameNotifier.new,
);

class UsernameNotifier extends AsyncNotifier<String?> {
  static const _key = 'username';

  @override
  Future<String?> build() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key);
  }

  Future<void> setUsername(String username) async {
    final trimmedUsername = username.trim();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_key, trimmedUsername);
      return trimmedUsername;
    });
  }

  Future<void> clearUsername() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_key);
      return null;
    });
  }
}
