
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';



class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;
   AppLocalizations(this.locale);

   static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(
      context, AppLocalizations
      )!;
    }
    Future<bool> load() async {
       final jsonString = await rootBundle
          .loadString('lib/core/localization/${locale.languageCode}.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
      return true;
    }
    String translate(String key) {
      return _localizedStrings[key] ?? key;
    }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}