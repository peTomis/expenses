import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:expenses/components/button/app_button.dart';
import 'package:expenses/components/text_input/app_text_input.dart';
import 'package:expenses/config/env.dart';
import 'package:expenses/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/shared_preferences');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          switch (methodCall.method) {
            case 'getAll':
              return <String, Object>{};
            case 'setBool':
            case 'setInt':
            case 'setDouble':
            case 'setString':
            case 'setStringList':
            case 'remove':
            case 'clear':
            case 'commit':
              return true;
            default:
              return null;
          }
        });

    await AppEnv.load();
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  });

  testWidgets('Shows login form by default', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppButton, 'Login'), findsOneWidget);
    expect(find.byType(AppTextInput), findsNWidgets(2));
    expect(find.byType(AppButton), findsOneWidget);
  });
}
