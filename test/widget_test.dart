import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expenses/components/button/app_button.dart';
import 'package:expenses/components/text_input/app_text_input.dart';
import 'package:expenses/main.dart';
import 'package:expenses/providers/shared_preferences_provider.dart';

void main() {
  late SharedPreferences preferences;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
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

    preferences = await SharedPreferences.getInstance();
  });

  testWidgets('Shows username form when no local account is set', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose an username'), findsOneWidget);
    expect(find.byType(AppTextInput), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Continue'), findsOneWidget);
  });
}
