import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// `/v1/cards/{id}/share_link`: create (`POST`) or revoke (`DELETE`) the
/// card's public link. Comes with the web card (roadmap step 4); answers
/// 501 until then.
Response onRequest(RequestContext context, String id) => Response.json(
  statusCode: HttpStatus.notImplemented,
  body: {'error': 'not_implemented'},
);
