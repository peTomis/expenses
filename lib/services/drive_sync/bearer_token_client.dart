import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'drive_auth_source.dart';

/// The one piece of Drive-calling code shared by every platform: attaches
/// a fresh bearer token (pulled from whichever [DriveAuthSource] is active)
/// to every outgoing request.
class BearerTokenClient extends http.BaseClient {
  BearerTokenClient(this._authSource, {http.Client? inner})
    : _inner = inner ?? http.Client();

  final DriveAuthSource _authSource;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _authSource.currentAccessToken();
    if (token == null) {
      throw StateError('Not signed in to Google Drive.');
    }

    request.headers['Authorization'] = 'Bearer $token';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

drive.DriveApi driveApiFor(DriveAuthSource authSource) {
  return drive.DriveApi(BearerTokenClient(authSource));
}
