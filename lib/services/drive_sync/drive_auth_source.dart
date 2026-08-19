/// The only scope this app ever requests for Drive: access to its own
/// hidden `appDataFolder`, never the user's visible files. Kept narrow
/// deliberately — Google classifies it as non-sensitive, which keeps the
/// OAuth consent screen out of Google's stricter security review.
const driveAppdataScope = 'https://www.googleapis.com/auth/drive.appdata';

/// A source of Drive-authenticated access, abstracting over however a given
/// platform actually signs the user in (google_sign_in on Android/iOS/
/// macOS/Web, a hand-built OAuth loopback flow on Windows). Everything that
/// talks to the Drive API is written once against this interface.
abstract class DriveAuthSource {
  /// A valid (non-expired) bearer token, or null if signed out. Safe to
  /// call before every request — implementations are expected to cache/
  /// refresh internally rather than force callers to track expiry.
  Future<String?> currentAccessToken();

  Future<void> signOut();

  /// Emits the signed-in account's email (or null on sign-out) for display
  /// in the UI.
  Stream<String?> get accountEmailChanges;
}
