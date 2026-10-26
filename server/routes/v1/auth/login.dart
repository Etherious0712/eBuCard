import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

/// `POST /v1/auth/login`: sign in with email + password.
///
/// Planned: check the Argon2id hash and return access + refresh tokens.
Response onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => notImplemented('POST /v1/auth/login'),
    _ => methodNotAllowed(),
  };
}
