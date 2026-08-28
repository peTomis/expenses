import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i18n/app_localizations.dart';
import 'pages/auth/auth_gate.dart';
import 'providers/color_provider.dart';
import 'providers/shared_preferences_provider.dart';
import 'services/macos_camera_delegate.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
    ),
  );

  // `image_picker_macos` has no built-in camera implementation and throws
  // unless a delegate is supplied.
  if (!kIsWeb && Platform.isMacOS) {
    final platform = ImagePickerPlatform.instance;
    if (platform is CameraDelegatingImagePickerPlatform) {
      platform.cameraDelegate = MacosCameraDelegate(rootNavigatorKey);
    }
  }

  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBackgroundColor = ref.watch(appBackgroundColorProvider);
    final appPrimaryTextColor = ref.watch(appPrimaryTextColorProvider);
    final appPrimaryColor = ref.watch(appPrimaryDefaultColorProvider);
    const appFontFamily = 'IBM Plex Sans Condensed';

    final lightTextTheme = ThemeData.light().textTheme.apply(
      fontFamily: appFontFamily,
      bodyColor: appPrimaryTextColor,
      displayColor: appPrimaryTextColor,
    );
    final darkTextTheme = ThemeData.dark().textTheme.apply(
      fontFamily: appFontFamily,
      bodyColor: appPrimaryTextColor,
      displayColor: appPrimaryTextColor,
    );

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Expenses',
      debugShowCheckedModeBanner: false,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: appPrimaryColor),
        fontFamily: appFontFamily,
        scaffoldBackgroundColor: appBackgroundColor,
        textTheme: lightTextTheme,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appPrimaryColor,
          brightness: Brightness.dark,
        ),
        fontFamily: appFontFamily,
        scaffoldBackgroundColor: appBackgroundColor,
        textTheme: darkTextTheme,
      ),
      home: const AuthGate(),
    );
  }
}
