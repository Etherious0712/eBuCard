import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

/// `POST /v1/auth/apple`: Sign in with Apple.
///
/// Planned: verify the Apple ID token against Apple's public keys, find or
/// create the user by `apple_sub`, and return eBuCard tokens.
Response onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => notImplemented('POST /v1/auth/apple'),
    _ => methodNotAllowed(),
  };
}
