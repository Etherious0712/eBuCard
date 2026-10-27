import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// `GET /c/{slug}`: the public web card for people without the app.
/// Comes with roadmap step 4; answers 501 until then.
Response onRequest(RequestContext context, String slug) => Response.json(
  statusCode: HttpStatus.notImplemented,
  body: {'error': 'not_implemented'},
);
