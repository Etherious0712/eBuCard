import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/email/server_strings.dart';
import 'package:ebucard_server/src/http/html_page.dart';
import 'package:ebucard_server/src/services.dart';

/// `GET /email/verify?token=…`: the link in the confirmation email. Shows a
/// page saying the email is confirmed (sync is now on), or that the link
/// expired or was used.
Future<Response> onRequest(RequestContext context) async {
  final strings = ServerStrings.of(
    localeFromHeader(context.request.headers['accept-language']),
  );
  final token = context.request.uri.queryParameters['token'] ?? '';
  final ok =
      token.isNotEmpty &&
      await context.read<Services>().accounts.verifyEmail(token);
  return ok
      ? htmlPage(
          strings,
          strings.verifiedTitle,
          bodyHtml: '<p>${escapeHtml(strings.verifiedBody)}</p>',
        )
      : htmlPage(
          strings,
          strings.linkInvalidTitle,
          bodyHtml: '<p>${escapeHtml(strings.linkInvalidBody)}</p>',
          status: HttpStatus.badRequest,
        );
}
