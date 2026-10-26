import 'package:ebucard/src/core/locale_resolution.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('non-Chinese and null locales fall back to English', () {
    expect(resolveAppLocale(null), const Locale('en'));
    expect(resolveAppLocale(const Locale('ja', 'JP')), const Locale('en'));
  });

  test('Chinese regions without a script code pick the right script', () {
    for (final region in ['TW', 'HK', 'MO']) {
      expect(resolveAppLocale(Locale('zh', region)).scriptCode, 'Hant');
    }
    expect(resolveAppLocale(const Locale('zh', 'CN')).scriptCode, 'Hans');
    expect(resolveAppLocale(const Locale('zh')).scriptCode, 'Hans');
  });

  test('explicit script code wins over region', () {
    const hansInHk = Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
      countryCode: 'HK',
    );
    expect(resolveAppLocale(hansInHk).scriptCode, 'Hans');
  });
}
