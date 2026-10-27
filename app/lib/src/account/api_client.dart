// Talks to the eBuCard server (see server/README.md for the endpoints).
//
// Requests carry a 15-minute access token. When the server answers 401, the
// client trades the refresh token for new tokens once and retries. If that
// fails too, the session is over and [onSessionExpired] is called.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'account.dart';
import 'session_store.dart';

/// An error from the server (`{"error": code}`) or the network.
class ApiError implements Exception {
  /// Creates an error.
  const ApiError(this.code, [this.status]);

  /// Stable code, e.g. `invalid_credentials`, or `network` when the server
  /// couldn't be reached.
  final String code;

  /// HTTP status, or null for network errors.
  final int? status;

  @override
  String toString() => 'ApiError($code, $status)';
}

/// Tokens and account returned by every sign-in.
class SignedIn {
  /// Creates the result.
  const SignedIn(this.accessToken, this.refreshToken, this.account);

  /// Reads a sign-in response.
  factory SignedIn.fromJson(Map<String, Object?> json) => SignedIn(
    json['accessToken']! as String,
    json['refreshToken']! as String,
    Account.fromJson(json['account']! as Map<String, Object?>),
  );

  /// Short-lived token for API calls.
  final String accessToken;

  /// Long-lived token, kept in secure storage.
  final String refreshToken;

  /// The account.
  final Account account;
}

/// HTTP client for the eBuCard API.
class ApiClient {
  /// Creates a client for the server at [baseUrl].
  ApiClient({
    required this.baseUrl,
    required this.sessions,
    http.Client? client,
    this.languageTag = 'en',
  }) : _http = client ?? http.Client();

  /// Server address (AppConfig.apiBaseUrl).
  final Uri baseUrl;

  /// Where the refresh token is kept.
  final SessionStore sessions;

  /// Sent as `Accept-Language` so emails come in the app's language.
  String languageTag;

  /// Called when the session can't be renewed (signed out elsewhere,
  /// 90 days unused, or account deleted).
  void Function()? onSessionExpired;

  final http.Client _http;
  String? _accessToken;
  Future<bool>? _refreshing;

  /// Starts a session from a sign-in response.
  Future<void> startSession(SignedIn signedIn) async {
    _accessToken = signedIn.accessToken;
    await sessions.save(StoredSession(signedIn.refreshToken, signedIn.account));
  }

  /// Forgets the tokens (after sign-out).
  Future<void> endSession() async {
    _accessToken = null;
    await sessions.clear();
  }

  /// `POST` without a session (sign-in, register, reset). Returns the JSON
  /// body, or an empty map for empty responses.
  Future<Map<String, Object?>> postPublic(
    String path,
    Map<String, Object?> body,
  ) async => _decode(await _send('POST', path, body: body));

  /// A request with the session; refreshes the access token when needed.
  Future<Map<String, Object?>> authed(
    String method,
    String path, {
    Object? body,
    Uint8List? bytes,
  }) async {
    var response = await _send(
      method,
      path,
      body: body,
      bytes: bytes,
      auth: true,
    );
    if (response.statusCode == 401 && await _refresh()) {
      response = await _send(
        method,
        path,
        body: body,
        bytes: bytes,
        auth: true,
      );
    }
    return _decode(response);
  }

  /// Trades the refresh token for new tokens. Concurrent callers share one
  /// refresh, because each refresh token works only once.
  Future<bool> _refresh() => _refreshing ??= () async {
    try {
      final stored = await sessions.load();
      if (stored == null) return false;
      final response = await _send(
        'POST',
        '/v1/auth/refresh',
        body: {'refreshToken': stored.refreshToken},
      );
      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          await endSession();
          onSessionExpired?.call();
        }
        return false;
      }
      await startSession(
        SignedIn.fromJson(jsonDecode(response.body) as Map<String, Object?>),
      );
      return true;
    } finally {
      _refreshing = null;
    }
  }();

  /// Sends one request; network failures become `ApiError('network')`.
  Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
    Uint8List? bytes,
    bool auth = false,
  }) async {
    final request = http.Request(method, baseUrl.resolve(path))
      ..headers['accept-language'] = languageTag;
    if (auth && _accessToken != null) {
      request.headers['authorization'] = 'Bearer $_accessToken';
    }
    if (bytes != null) {
      request
        ..headers['content-type'] = 'application/octet-stream'
        ..bodyBytes = bytes;
    } else if (body != null) {
      request
        ..headers['content-type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    try {
      return await http.Response.fromStream(
        await _http.send(request).timeout(const Duration(seconds: 20)),
      );
    } on Object {
      throw const ApiError('network');
    }
  }

  /// The JSON body of a successful response, or an [ApiError].
  Map<String, Object?> _decode(http.Response response) {
    Object? json;
    try {
      json = response.body.isEmpty
          ? <String, Object?>{}
          : jsonDecode(response.body);
    } on FormatException {
      json = null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json is Map<String, Object?> ? json : {};
    }
    final code = json is Map<String, Object?> && json['error'] is String
        ? json['error']! as String
        : 'http_${response.statusCode}';
    throw ApiError(code, response.statusCode);
  }
}
