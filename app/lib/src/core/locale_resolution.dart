import 'package:flutter/widgets.dart';

const supportedAppLocales = [
  Locale('en'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
];

const _traditionalChineseRegions = {'TW', 'HK', 'MO'};

/// Picks English, Traditional or Simplified Chinese for a device locale.
///
/// Devices often report Chinese without a script code (e.g. `zh_TW`), so the
/// region decides the script when the script is missing. Anything that is not
/// Chinese falls back to English.
Locale resolveAppLocale(Locale? device) {
  if (device == null || device.languageCode != 'zh') {
    return supportedAppLocales.first;
  }
  final script =
      device.scriptCode ??
      (_traditionalChineseRegions.contains(device.countryCode)
          ? 'Hant'
          : 'Hans');
  return Locale.fromSubtags(languageCode: 'zh', scriptCode: script);
}
