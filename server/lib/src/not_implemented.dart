import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// Placeholder response for endpoints defined in docs/DESIGN.md but not yet
/// implemented.
Response notImplemented(String endpoint) => Response.json(
  statusCode: HttpStatus.notImplemented,
  body: {'error': 'not_implemented', 'endpoint': endpoint},
);

/// Response for an HTTP method a route does not support.
Response methodNotAllowed() =>
    Response(statusCode: HttpStatus.methodNotAllowed);
