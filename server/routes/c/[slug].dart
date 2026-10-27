import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:ebucard_server/src/email/server_strings.dart';
import 'package:ebucard_server/src/http/api_error.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';
import 'package:ebucard_server/src/web/web_card.dart';

/// `GET /c/{slug}`: a public card link (DESIGN.md §4.1).
///
/// * Browsers get the web card page, in the visitor's language.
/// * `?format=vcf` or `Accept: text/vcard` downloads the contact file.
/// * `?format=json` or `Accept: application/json` gives the card JSON the
///   app saves to the Inbox.
///
/// A revoked, replaced or unknown link answers 404. Requests are rate
/// limited per address so slugs can't be tried in bulk.
Future<Response> onRequest(RequestContext context, String slug) async {
  allowMethods(context, {HttpMethod.get, HttpMethod.head});
  final services = context.read<Services>()..linkLimiter.hit(clientIp(context));
  final request = context.request;
  final format = _format(
    request.uri.queryParameters['format'],
    request.headers['accept'] ?? '',
  );
  final strings = ServerStrings.of(
    localeFromHeader(request.headers['accept-language']),
  );

  final found = await services.shareLinks.find(slug);
  if (found == null) {
    return switch (format) {
      _Format.html => cardGonePage(strings),
      _Format.json => throw const ApiException.notFound(),
      _Format.vcf => Response(statusCode: HttpStatus.notFound),
    };
  }
  final card = BusinessCard.fromJson(found.data);
  final response = switch (format) {
    _Format.json => cardJsonResponse(card),
    _Format.vcf => vcardResponse(card),
    _Format.html => webCardPage(
      strings,
      card,
      cardUrl: services.config.publicBaseUrl.replace(path: '/c/$slug'),
      imageBase: services.images.urlFor('').toString(),
      appLinks: services.config.appLinks,
    ),
  };
  return response.copyWith(
    headers: {...response.headers, 'vary': 'Accept, Accept-Language'},
  );
}

/// What the caller asked for.
enum _Format { html, vcf, json }

/// Picks the format from `?format=` first, then the `Accept` header.
_Format _format(String? query, String accept) {
  switch (query) {
    case 'vcf':
      return _Format.vcf;
    case 'json':
      return _Format.json;
  }
  final a = accept.toLowerCase();
  if (a.contains('text/vcard') || a.contains('text/x-vcard')) {
    return _Format.vcf;
  }
  if (a.contains('application/json') && !a.contains('text/html')) {
    return _Format.json;
  }
  return _Format.html;
}
