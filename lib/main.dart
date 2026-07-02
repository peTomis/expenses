import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'i18n/app_localizations.dart';
import 'pages/auth/auth_gate.dart';
import 'providers/color_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
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
