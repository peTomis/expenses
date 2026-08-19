import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'drive_auth_source.dart';

/// Android/iOS/macOS/Web implementation, backed by the official
/// `google_sign_in` v7 package.
///
/// v7 splits *authentication* (who the user is, via [signIn]) from
/// *authorization* (what scopes the app can access, via
/// `authorizationClient`), and on web `authenticate()` throws
/// `UnimplementedError` — web sign-in only ever happens through the
/// rendered Google button, whose result arrives through the same
/// [accountEmailChanges]/`authenticationEvents` stream every platform uses.
class GoogleSignInAuthSource implements DriveAuthSource {
  GoogleSignInAuthSource({this.clientId, this.serverClientId});

  /// OAuth client id for platforms that need one passed explicitly
  /// (iOS/macOS/Web). Android normally resolves it from the registered
  /// package name + SHA-1 and can leave this null.
  final String? clientId;
  final String? serverClientId;

  final GoogleSignIn _instance = GoogleSignIn.instance;
  final _emailController = StreamController<String?>.broadcast();

  GoogleSignInAccount? _currentUser;
  Future<void>? _initialization;

  @override
  Future<void> ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    await _instance.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    _instance.authenticationEvents.listen(
      _handleAuthenticationEvent,
      onError: (Object _) {
        _currentUser = null;
        _emailController.add(null);
      },
    );

    if (!kIsWeb) {
      // Silently restores a previous session, if any, without prompting.
      await _instance.attemptLightweightAuthentication();
    }
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        _currentUser = event.user;
        _emailController.add(event.user.email);
      case GoogleSignInAuthenticationEventSignOut():
        _currentUser = null;
        _emailController.add(null);
    }
  }

  /// Triggers the native account picker / Credential Manager sheet. Not
  /// usable on web — there, sign-in happens through the rendered Google
  /// button instead, and its result surfaces the same way (through
  /// [accountEmailChanges]).
  @override
  Future<void> signIn() async {
    await ensureInitialized();
    await _instance.authenticate();
  }

  @override
  Future<String?> currentAccessToken() async {
    await ensureInitialized();
    final user = _currentUser;
    if (user == null) {
      return null;
    }

    // Silent check first — already-granted scopes come back with no UI.
    final cached = await user.authorizationClient.authorizationForScopes([
      driveAppdataScope,
    ]);
    if (cached != null) {
      return cached.accessToken;
    }

    // Not yet granted (first Drive access ever, or — on web, where tokens
    // aren't auto-refreshed and expire after an hour — simply stale).
    // This may prompt the user once; after that it's cached like any
    // other granted scope.
    try {
      final authorized = await user.authorizationClient.authorizeScopes([
        driveAppdataScope,
      ]);
      return authorized.accessToken;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await ensureInitialized();
    await _instance.signOut();
  }

  @override
  Stream<String?> get accountEmailChanges => _emailController.stream;
}
