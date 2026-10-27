// Small helpers shared by route handlers.

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/api_error.dart';

/// Reads the request body as a JSON object, or throws a 400.
Future<Map<String, Object?>> readJsonObject(RequestContext context) async {
  try {
    final body = jsonDecode(await context.request.body());
    if (body is Map<String, Object?>) return body;
  } on FormatException {
    // Fall through to the error below.
  }
  throw const ApiException.badRequest('invalid_json');
}

/// A required, non-empty string field from [json], or a 400 naming it.
String requireString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String && value.trim().isNotEmpty) return value;
  throw ApiException.badRequest('missing_field', {'field': field});
}

/// The client's IP address. On Cloud Run the first `X-Forwarded-For`
/// entry is the client; locally it is the socket address.
String clientIp(RequestContext context) {
  final forwarded = context.request.headers['x-forwarded-for'];
  if (forwarded != null && forwarded.isNotEmpty) {
    return forwarded.split(',').first.trim();
  }
  return context.request.connectionInfo.remoteAddress.address;
}

/// The value of an `Authorization: Bearer <token>` header, or null.
String? bearerToken(RequestContext context) {
  final header = context.request.headers['authorization'];
  if (header == null || !header.toLowerCase().startsWith('bearer ')) {
    return null;
  }
  return header.substring(7).trim();
}

/// Whether [s] is a UUID. Ids are checked before they reach SQL casts, so
/// a malformed id is a 404 rather than a database error.
bool isUuid(String s) => RegExp(
  r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$',
  caseSensitive: false,
).hasMatch(s);

/// Throws a 405 unless the request uses one of [methods].
void allowMethods(RequestContext context, Set<HttpMethod> methods) {
  if (!methods.contains(context.request.method)) {
    throw const ApiException(405, 'method_not_allowed');
  }
}
