// An in-memory stand-in for the eBuCard server, speaking the same HTTP API
// (server/README.md) through `package:http`'s MockClient. It follows the
// real server's rules for sign-in, token rotation, email confirmation,
// sync (last writer wins, tombstones, paging) and card links, so app tests
// exercise the real client and sync engine.

import 'dart:convert';
import 'dart:typed_data';

import 'package:ebucard/src/account/account.dart';
import 'package:ebucard/src/account/session_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// One account on the fake server.
class FakeUser {
  /// Creates a user.
  FakeUser(this.id, this.email, this.password, {this.verified = false});

  /// Account id.
  final String id;

  /// Email address.
  final String email;

  /// Password (plain text: it's a test).
  String password;

  /// Whether the email is confirmed.
  bool verified;

  /// Whether deletion was requested.
  bool deleted = false;

  /// JSON as the real server returns it.
  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'emailVerified': verified,
    'canSync': verified,
    'hasPassword': true,
    'apple': false,
    'google': false,
  };
}

/// A stored record (card or Inbox entry).
class FakeRecord {
  /// Creates a record.
  FakeRecord(this.data, this.updatedAt, this.seq);

  /// JSON, or null when deleted.
  Map<String, Object?>? data;

  /// Last change on a phone.
  DateTime updatedAt;

  /// Position in the change list.
  int seq;
}

/// The fake server. Use [client] as the app's HTTP client.
class FakeServer {
  /// Accounts by email.
  final users = <String, FakeUser>{};

  /// Records by user id, kind (`cards`/`received`) and record id.
  final records = <String, Map<String, Map<String, FakeRecord>>>{};

  /// Uploaded images by id.
  final images = <String, Uint8List>{};

  /// Every request path, for assertions.
  final requests = <String>[];

  /// When false, every request fails like a phone without signal.
  bool online = true;

  /// Page size for change lists (small, to exercise paging).
  int pageSize = 50;

  /// Card link slugs by card id; cards whose owner turned the link off.
  final _slugs = <String, String>{};
  final _revoked = <String>{};

  /// Gives card [cardId] the link [slug] (for cards put with
  /// [putFromOtherPhone]).
  void linkSlug(String cardId, String slug) => _slugs[cardId] = slug;

  /// Turns off the link of card [cardId], as its owner can.
  void unlinkSlug(String cardId) {
    _slugs.remove(cardId);
    _revoked.add(cardId);
  }

  /// The card behind link [slug] (any user), or null.
  Map<String, Object?>? cardForSlug(String slug) {
    for (final kinds in records.values) {
      for (final e in (kinds['cards'] ?? {}).entries) {
        if (e.value.data != null && _slugs[e.key] == slug) return e.value.data;
      }
    }
    return null;
  }

  /// Changes card [id]'s link to [slug] (null = off), as the server does
  /// for share_link: the record moves to the end of the change list.
  FakeRecord? _setSlug(FakeUser user, String id, String? slug) {
    final record = records[user.id]?['cards']?[id];
    if (record == null || record.data == null) return null;
    if (slug == null) {
      _slugs.remove(id);
      _revoked.add(id);
    } else {
      _slugs[id] = slug;
      _revoked.remove(id);
    }
    record
      ..data = {...record.data!, 'shareSlug': slug}
      ..seq = ++_seq;
    return record;
  }

  final _access = <String, String>{};
  final _refresh = <String, String>{};
  final _usedRefresh = <String>{};
  var _seq = 0;
  var _ids = 0;

  /// The HTTP client the app should use.
  late final http.Client client = MockClient(_handle);

  /// Creates an account directly (as if registered earlier).
  FakeUser addUser(String email, String password, {bool verified = true}) {
    final user = FakeUser(
      'user-${++_ids}',
      email,
      password,
      verified: verified,
    );
    users[email] = user;
    return user;
  }

  /// A stored session for [user], as if the phone had signed in earlier.
  /// Pass it to `MemorySessionStore` to start a test signed in.
  StoredSession sessionFor(FakeUser user) {
    final refresh = 'refresh-${++_ids}';
    _refresh[refresh] = user.id;
    return StoredSession(refresh, Account.fromJson(user.toJson()));
  }

  /// Ends every session (as if the user signed out elsewhere long ago).
  void expireSessions() {
    _access.clear();
    _refresh.clear();
  }

  /// Ends the current access tokens only (as after 15 minutes).
  void expireAccessTokens() => _access.clear();

  /// The live (not deleted) records of [user] of [kind], by id.
  Map<String, Map<String, Object?>> live(FakeUser user, String kind) => {
    for (final e in (records[user.id]?[kind] ?? {}).entries)
      if (e.value.data != null) e.key: e.value.data!,
  };

  /// Stores a record as if another phone had synced it.
  void putFromOtherPhone(
    FakeUser user,
    String kind,
    String id,
    Map<String, Object?>? data,
    DateTime updatedAt,
  ) => _store(user, kind, id, data, updatedAt);

  Future<http.Response> _handle(http.Request request) async {
    if (!online) throw http.ClientException('offline');
    final path = request.url.path;
    requests.add('${request.method} $path');
    final isJson = (request.headers['content-type'] ?? '').startsWith(
      'application/json',
    );
    // Only JSON bodies are read as text; image uploads are raw bytes.
    final body = !isJson || request.body.isEmpty
        ? <String, Object?>{}
        : jsonDecode(request.body) as Map<String, Object?>;

    switch ((request.method, path)) {
      case ('POST', '/v1/auth/register'):
        final email = (body['email']! as String).toLowerCase();
        if (users.containsKey(email)) return _error(409, 'email_taken');
        if ((body['password']! as String).length < 8) {
          return _error(400, 'password_too_short');
        }
        final user = addUser(
          email,
          body['password']! as String,
          verified: false,
        );
        return _signIn(user, status: 201);
      case ('POST', '/v1/auth/login'):
        final user = users[(body['email']! as String).toLowerCase()];
        if (user == null || user.password != body['password']) {
          return _error(401, 'invalid_credentials');
        }
        user.deleted = false;
        return _signIn(user);
      case ('POST', '/v1/auth/refresh'):
        final token = body['refreshToken']! as String;
        final userId = _refresh.remove(token);
        if (userId == null || _usedRefresh.contains(token)) {
          return _error(401, 'invalid_refresh_token');
        }
        _usedRefresh.add(token);
        return _signIn(users.values.firstWhere((u) => u.id == userId));
      case ('POST', '/v1/auth/logout'):
        _refresh.remove(body['refreshToken']);
        return http.Response('', 204);
      case ('POST', '/v1/auth/password_reset'):
        return http.Response('', 202);
      case ('POST', '/v1/auth/apple' || '/v1/auth/google'):
        // Any identity token signs in one provider-confirmed account.
        final email = '${path.split('/').last}-user@x.com';
        final user = users[email] ?? addUser(email, 'not-used', verified: true);
        return _signIn(user);
    }

    final link = RegExp(r'^/c/([^/]+)$').firstMatch(path);
    if (link != null && request.method == 'GET') {
      final card = cardForSlug(link.group(1)!);
      return card == null ? _error(404, 'not_found') : _json({'card': card});
    }

    final user = _user(request);
    if (user == null) return _error(401, 'unauthorized');

    switch ((request.method, path)) {
      case ('GET', '/v1/account'):
        return _json(user.toJson());
      case ('DELETE', '/v1/account'):
        user.deleted = true;
        _refresh.removeWhere((_, id) => id == user.id);
        return _json({'deleteAfter': '2026-12-01T00:00:00Z'}, 202);
      case ('POST', '/v1/auth/resend_verification'):
        return http.Response('', 204);
    }

    if (!user.verified) return _error(403, 'email_not_verified');

    if (request.method == 'POST' && path == '/v1/images') {
      final id = 'img-${++_ids}';
      images[id] = request.bodyBytes;
      return _json({
        'id': id,
        'url': 'https://api.example.com/images/$id',
      }, 201);
    }

    final share = RegExp(r'^/v1/cards/([^/]+)/share_link$').firstMatch(path);
    if (share != null) {
      final id = share.group(1)!;
      final record = _setSlug(
        user,
        id,
        request.method == 'POST' ? 'slug-${++_ids}' : null,
      );
      return record == null
          ? _error(404, 'not_found')
          : _json(_recordJson(id, record));
    }

    final match = RegExp(
      r'^/v1/(cards|received)(?:/([^/]+))?$',
    ).firstMatch(path);
    if (match == null) return _error(404, 'not_found');
    final kind = match.group(1)!;
    final id = match.group(2);
    if (id == null && request.method == 'GET') {
      final since = int.parse(request.url.queryParameters['since'] ?? '0');
      final changed =
          (records[user.id]?[kind] ?? {}).entries
              .where((e) => e.value.seq > since)
              .toList()
            ..sort((a, b) => a.value.seq.compareTo(b.value.seq));
      final page = changed.take(pageSize).toList();
      return _json({
        'changes': [for (final e in page) _recordJson(e.key, e.value)],
        'cursor': page.isEmpty ? since : page.last.value.seq,
        'hasMore': changed.length > page.length,
      });
    }
    if (id == null) return _error(405, 'method_not_allowed');
    if (request.method == 'PUT') {
      final updatedAt = DateTime.parse(body['updatedAt']! as String);
      // Like the real server: only its own image URLs are kept.
      final data = Map<String, Object?>.from(body);
      if (kind == 'cards') {
        for (final f in ['photoUrl', 'logoUrl']) {
          final url = data[f] as String?;
          if (url != null &&
              !url.startsWith('https://api.example.com/images/')) {
            data[f] = null;
          }
        }
        // The server owns the link: made on first sync unless turned off.
        if (!_revoked.contains(id)) {
          _slugs.putIfAbsent(id, () => 'slug-${++_ids}');
        }
        data['shareSlug'] = _slugs[id];
      }
      return _json(_recordJson(id, _store(user, kind, id, data, updatedAt)));
    }
    if (request.method == 'DELETE') {
      if (kind == 'cards') _slugs.remove(id);
      final updatedAt = DateTime.parse(body['updatedAt']! as String);
      return _json(_recordJson(id, _store(user, kind, id, null, updatedAt)));
    }
    return _error(405, 'method_not_allowed');
  }

  /// Last-writer-wins store; returns the record now kept.
  FakeRecord _store(
    FakeUser user,
    String kind,
    String id,
    Map<String, Object?>? data,
    DateTime updatedAt,
  ) {
    final table = records
        .putIfAbsent(user.id, () => {})
        .putIfAbsent(kind, () => {});
    final existing = table[id];
    if (existing != null && !updatedAt.isAfter(existing.updatedAt)) {
      return existing;
    }
    return table[id] = FakeRecord(data, updatedAt, ++_seq);
  }

  Map<String, Object?> _recordJson(String id, FakeRecord r) => {
    'id': id,
    'deleted': r.data == null,
    'updatedAt': r.updatedAt.toUtc().toIso8601String(),
    if (r.data != null) 'data': r.data,
  };

  FakeUser? _user(http.Request request) {
    final header = request.headers['authorization'] ?? '';
    final userId = _access[header.replaceFirst('Bearer ', '')];
    if (userId == null) return null;
    final user = users.values.firstWhere((u) => u.id == userId);
    return user.deleted ? null : user;
  }

  http.Response _signIn(FakeUser user, {int status = 200}) {
    final access = 'access-${++_ids}';
    final refresh = 'refresh-${++_ids}';
    _access[access] = user.id;
    _refresh[refresh] = user.id;
    return _json({
      'accessToken': access,
      'refreshToken': refresh,
      'expiresIn': 900,
      'account': user.toJson(),
    }, status);
  }

  static http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  static http.Response _error(int status, String code) =>
      _json({'error': code}, status);
}
