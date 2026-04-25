import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'i18n/app_localizations.dart';
import 'pages/auth/auth_gate.dart';
import 'providers/color_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
    ),
  );

  await AppEnv.load();

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
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
        scaffoldBackgroundColor: appBackgroundColor,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: appPrimaryTextColor,
          displayColor: appPrimaryTextColor,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appPrimaryColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: appBackgroundColor,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: appPrimaryTextColor,
          displayColor: appPrimaryTextColor,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
