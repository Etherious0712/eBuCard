import 'package:ebucard_server/src/config.dart';
import 'package:ebucard_server/src/email/server_strings.dart';
import 'package:ebucard_server/src/http/api_error.dart';
import 'package:ebucard_server/src/http/html_page.dart';
import 'package:ebucard_server/src/http/rate_limiter.dart';
import 'package:test/test.dart';

void main() {
  group('localeFromHeader', () {
    test('picks the same language as the app', () {
      expect(localeFromHeader(null), ServerLocale.en);
      expect(localeFromHeader('ja-JP,ja;q=0.9'), ServerLocale.en);
      expect(localeFromHeader('zh-TW,zh;q=0.9'), ServerLocale.zhHant);
      expect(localeFromHeader('zh-HK'), ServerLocale.zhHant);
      expect(localeFromHeader('zh-Hant-HK'), ServerLocale.zhHant);
      expect(localeFromHeader('zh-CN'), ServerLocale.zhHans);
      expect(localeFromHeader('zh_Hans'), ServerLocale.zhHans);
      expect(localeFromHeader('fr-FR, zh-HK;q=0.5'), ServerLocale.zhHant);
      expect(localeFromHeader('en-GB, zh-CN;q=0.5'), ServerLocale.en);
    });

    test('every language has every string', () {
      for (final locale in ServerLocale.values) {
        final s = ServerStrings.of(locale);
        expect(s.verifyBody('L'), contains('L'));
        expect(s.resetBody('L'), contains('L'));
        expect(
          [s.resetTitle, s.passwordBreached, s.resetDoneBody],
          everyElement(isNotEmpty),
        );
      }
    });
  });

  test('HTML is escaped', () {
    expect(
      escapeHtml('<script>"x" & \'y\''),
      '&lt;script&gt;&quot;x&quot; &amp; &#39;y&#39;',
    );
  });

  test('rate limiter allows the limit per window, per key', () {
    var now = DateTime.utc(2026);
    final limiter =
        RateLimiter(
            limit: 2,
            window: const Duration(minutes: 10),
            now: () => now,
          )
          ..hit('a')
          ..hit('a')
          ..hit('b');
    expect(() => limiter.hit('a'), throwsA(isA<ApiException>()));
    now = now.add(const Duration(minutes: 11));
    expect(() => limiter.hit('a'), returnsNormally);
  });

  group('Config', () {
    test('requires a long JWT secret', () {
      expect(
        () => Config.fromEnvironment({}),
        throwsA(isA<ConfigException>()),
      );
      expect(
        () => Config.fromEnvironment({'JWT_SECRET': 'short'}),
        throwsA(isA<ConfigException>()),
      );
    });

    test('defaults to the placeholder domain and optional services', () {
      final config = Config.fromEnvironment({'JWT_SECRET': 'x' * 32});
      expect(config.publicBaseUrl.host, 'api.example.com');
      expect(config.smtp, isNull);
      expect(config.storage, isNull);
      expect(config.appleClientIds, isEmpty);
    });

    test('reads SMTP, storage and client ids', () {
      final config = Config.fromEnvironment({
        'JWT_SECRET': 'x' * 32,
        'SMTP_HOST': 'smtp.example.com',
        'SMTP_FROM': 'eBuCard <no-reply@example.com>',
        'S3_BUCKET': 'ebucard-images',
        'S3_ACCESS_KEY': 'GOOG1EXAMPLE',
        'S3_SECRET_KEY': 'secret',
        'APPLE_CLIENT_IDS': 'com.etherious.ebucard, com.etherious.ebucard.web',
      });
      expect(config.smtp!.port, 587);
      expect(config.storage!.endpoint.host, 'storage.googleapis.com');
      expect(config.appleClientIds, hasLength(2));
    });

    test('names missing storage keys', () {
      expect(
        () =>
            Config.fromEnvironment({'JWT_SECRET': 'x' * 32, 'S3_BUCKET': 'b'}),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.missing,
            'missing',
            ['S3_ACCESS_KEY', 'S3_SECRET_KEY'],
          ),
        ),
      );
    });
  });
}
