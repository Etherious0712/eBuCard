// The two files phones check before opening card links in the app instead
// of the browser (DESIGN.md §4.1): Android App Links read
// `/.well-known/assetlinks.json`, iOS Universal Links read
// `/.well-known/apple-app-site-association`. Each is served only once its
// setting exists (APPLE_TEAM_ID, ANDROID_CERT_SHA256).

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/config.dart';
import 'package:ebucard_server/src/services.dart';

/// Serves the app-link files under `/.well-known/`; passes every other
/// request on.
Middleware appLinkFiles() =>
    (handler) => (context) {
      final path = context.request.uri.path;
      if (!path.startsWith('/.well-known/')) return handler(context);
      final config = context.read<Services>().config.appLinks;
      final body = switch (path) {
        '/.well-known/assetlinks.json' => assetLinks(config),
        '/.well-known/apple-app-site-association' => appleAppSiteAssociation(
          config,
        ),
        _ => null,
      };
      if (body == null) return Response(statusCode: 404);
      return Response(
        headers: {
          'content-type': 'application/json',
          'cache-control': 'public, max-age=3600',
        },
        body: jsonEncode(body),
      );
    };

/// `assetlinks.json`, or null without Android certificate fingerprints.
Object? assetLinks(AppLinksConfig config) => config.androidCertSha256.isEmpty
    ? null
    : [
        {
          'relation': ['delegate_permission/common.handle_all_urls'],
          'target': {
            'namespace': 'android_app',
            'package_name': AppLinksConfig.appId,
            'sha256_cert_fingerprints': config.androidCertSha256,
          },
        },
      ];

/// `apple-app-site-association`, or null without an Apple Team ID. Only
/// card links (`/c/*`) open the app.
Object? appleAppSiteAssociation(AppLinksConfig config) {
  final team = config.appleTeamId;
  if (team == null || team.isEmpty) return null;
  return {
    'applinks': {
      'details': [
        {
          'appIDs': ['$team.${AppLinksConfig.appId}'],
          'components': [
            {'/': '/c/*'},
          ],
        },
      ],
    },
  };
}
