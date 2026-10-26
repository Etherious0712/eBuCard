import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

/// `POST /v1/auth/register`: create an account with email + password.
///
/// Planned: validate the email, hash the password with Argon2id, send a
/// verification email, and return access + refresh tokens (DESIGN.md §7).
Response onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => notImplemented('POST /v1/auth/register'),
    _ => methodNotAllowed(),
  };
}
