import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authSessionProvider = StreamProvider<Session?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);

  yield client.auth.currentSession;

  await for (final authState in client.auth.onAuthStateChange) {
    yield authState.session;
  }
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}

class AuthFormState {
  const AuthFormState({required this.isLoginMode, required this.isSubmitting});

  final bool isLoginMode;
  final bool isSubmitting;

  AuthFormState copyWith({bool? isLoginMode, bool? isSubmitting}) {
    return AuthFormState(
      isLoginMode: isLoginMode ?? this.isLoginMode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class AuthFormNotifier extends Notifier<AuthFormState> {
  @override
  AuthFormState build() {
    return const AuthFormState(isLoginMode: true, isSubmitting: false);
  }

  void toggleMode() {
    state = state.copyWith(isLoginMode: !state.isLoginMode);
  }

  void setSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value);
  }
}

final authFormProvider = NotifierProvider<AuthFormNotifier, AuthFormState>(
  AuthFormNotifier.new,
);
