import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

/// `POST /v1/auth/google`: Google sign-in.
///
/// Planned: verify the Google ID token, find or create the user by
/// `google_sub`, and return eBuCard tokens.
Response onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => notImplemented('POST /v1/auth/google'),
    _ => methodNotAllowed(),
  };
}
