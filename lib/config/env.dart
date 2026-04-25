import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  const AppEnv._();

  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const _envFile = String.fromEnvironment('ENV_FILE');

  static String get fileName {
    if (_envFile.isNotEmpty) {
      return _envFile;
    }

    return 'env/.env.$environment';
  }

  static Future<void> load() {
    return dotenv.load(fileName: fileName);
  }

  static String get supabaseUrl => _required('SUPABASE_URL');

  static String get supabaseAnonKey => _required('SUPABASE_ANON_KEY');

  static String _required(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('$key is missing from $fileName');
    }

    return value;
  }
}
