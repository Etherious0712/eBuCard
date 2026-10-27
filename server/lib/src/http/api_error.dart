// Errors the API returns, as `{"error": "<code>"}` JSON. The app maps each
// code to a translated message, so codes must stay stable.

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// An error to send to the client. Thrown anywhere while handling a
/// request; [errorHandler] turns it into a response.
class ApiException implements Exception {
  /// Creates an error with HTTP [status] and machine-readable [code].
  const ApiException(this.status, this.code, [this.details]);

  /// 400: the request body is missing fields or malformed.
  const ApiException.badRequest([String code = 'bad_request', Object? details])
    : this(HttpStatus.badRequest, code, details);

  /// 401: missing, expired or invalid credentials.
  const ApiException.unauthorized([String code = 'unauthorized'])
    : this(HttpStatus.unauthorized, code);

  /// 403: signed in, but not allowed (e.g. email not verified).
  const ApiException.forbidden(String code) : this(HttpStatus.forbidden, code);

  /// 404: not found (also used for other users' data, so ids can't be
  /// probed).
  const ApiException.notFound() : this(HttpStatus.notFound, 'not_found');

  /// 409: conflicts with existing data (e.g. email already registered).
  const ApiException.conflict(String code) : this(HttpStatus.conflict, code);

  /// 429: too many requests from this address.
  const ApiException.tooManyRequests()
    : this(HttpStatus.tooManyRequests, 'too_many_requests');

  /// HTTP status code.
  final int status;

  /// Stable error code, e.g. `invalid_credentials`.
  final String code;

  /// Optional extra information (e.g. which fields failed validation).
  final Object? details;

  @override
  String toString() => 'ApiException($status, $code)';
}

/// Middleware that turns [ApiException]s into JSON error responses.
Middleware errorHandler() =>
    (handler) => (context) async {
      try {
        return await handler(context);
      } on ApiException catch (e) {
        return Response.json(
          statusCode: e.status,
          body: {'error': e.code, if (e.details != null) 'details': e.details},
        );
      }
    };
