// Reads a JWT's header without verifying it, so callers can insist on the
// algorithm they expect before verification. The JWT library would
// otherwise use whatever algorithm the token itself names.

import 'dart:convert';

/// The token's header fields, or null if it isn't a well-formed JWT.
Map<String, Object?>? jwtHeader(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final padded = parts[0].padRight((parts[0].length + 3) ~/ 4 * 4, '=');
    final header = jsonDecode(utf8.decode(base64Url.decode(padded)));
    return header is Map<String, Object?> ? header : null;
  } on FormatException {
    return null;
  }
}
