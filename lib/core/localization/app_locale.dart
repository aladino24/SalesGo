import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../storage/local_storage.dart';

/// Locale UI aplikasi.
///
/// Nilai tanggal, angka, API payload, dan data Hive tidak pernah diubah oleh
/// kelas ini. Locale hanya dipakai ketika nilai tersebut ditampilkan ke user.
class AppLocale {
  AppLocale._();

  static const storageKey = 'app_locale';
  static const indonesian = Locale('id', 'ID');
  static const english = Locale('en', 'US');
  static const supportedLocales = [indonesian, english];

  static Locale get current {
    final stored = LocalStorage.appBox.get(storageKey, defaultValue: 'id')
        .toString();
    return stored == 'en' ? english : indonesian;
  }

  static String get intlName => current.languageCode == 'en' ? 'en_US' : 'id_ID';

  static String get languageLabel => current.languageCode == 'en' ? 'English' : 'Indonesia';

  static Future<void> initialize() async {
    await initializeDateFormatting('id_ID');
    await initializeDateFormatting('en_US');
    Intl.defaultLocale = intlName;
  }

  static Future<void> update(String languageCode) async {
    final locale = languageCode == 'en' ? english : indonesian;
    await LocalStorage.appBox.put(storageKey, locale.languageCode);
    Intl.defaultLocale = locale.languageCode == 'en' ? 'en_US' : 'id_ID';
    await Get.updateLocale(locale);
  }

  static DateFormat date(String pattern) => DateFormat(pattern, intlName);

  static NumberFormat number({int? decimalDigits}) => NumberFormat.decimalPatternDigits(
        locale: intlName,
        decimalDigits: decimalDigits,
      );

  static NumberFormat currency({String symbol = 'Rp', int decimalDigits = 0}) =>
      NumberFormat.currency(
        locale: intlName,
        symbol: symbol,
        decimalDigits: decimalDigits,
      );
}
