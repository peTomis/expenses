import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  const AppLocalizations(this.locale, this._strings);

  final Locale locale;
  final Map<String, String> _strings;

  static const supportedLocales = [Locale('en')];

  static const localizationsDelegates = [AppLocalizationsDelegate()];

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );

    if (localizations == null) {
      throw StateError('AppLocalizations were not found in the widget tree.');
    }

    return localizations;
  }

  String text(String key) {
    return _strings[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final languageCode = isSupported(locale) ? locale.languageCode : 'en';
    final jsonString = await rootBundle.loadString(
      'assets/i18n/$languageCode.json',
    );
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    final strings = jsonMap.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return AppLocalizations(Locale(languageCode), strings);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) {
    return false;
  }
}
