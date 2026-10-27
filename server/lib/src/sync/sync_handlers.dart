// Request handling shared by the card and Inbox sync routes: read changes,
// write a record, delete a record. Incoming data is checked with the same
// rules the app uses (ebucard_models) before it is stored.

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:ebucard_server/src/http/api_error.dart';
import 'package:ebucard_server/src/http/auth_guard.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';
import 'package:ebucard_server/src/sync/sync_store.dart';

/// Largest accepted record body. Cards without images are a few KB.
const _maxBodyBytes = 64 * 1024;

/// `GET …?since=<cursor>`: changes after the cursor (0 = everything).
Future<Response> listChanges(RequestContext context, SyncKind kind) async {
  final user = await requireUser(context, requireSync: true);
  final since =
      int.tryParse(context.request.uri.queryParameters['since'] ?? '0') ?? 0;
  final page = await context.read<Services>().sync.changesSince(
    user.id,
    kind,
    since,
  );
  return Response.json(body: page.toJson());
}

/// `PUT …/{id}`: stores the record in the body if it is newer than the
/// server's copy, and returns whichever version is now stored.
Future<Response> putRecord(
  RequestContext context,
  SyncKind kind,
  String id,
) async {
  final user = await requireUser(context, requireSync: true);
  _checkId(id);
  final raw = await context.request.body();
  if (utf8.encode(raw).length > _maxBodyBytes) {
    throw const ApiException(413, 'record_too_large');
  }
  final Object? json;
  try {
    json = jsonDecode(raw);
  } on FormatException {
    throw const ApiException.badRequest('invalid_json');
  }
  if (json is! Map<String, Object?>) {
    throw const ApiException.badRequest('invalid_json');
  }
  final services = context.read<Services>();
  final (data, updatedAt) = switch (kind) {
    SyncKind.cards => _checkCard(json, id, services),
    SyncKind.received => _checkReceived(json, id),
  };
  final stored = await services.sync.write(user.id, kind, id, data, updatedAt);
  return Response.json(body: stored.toJson());
}

/// `DELETE …/{id}` `{updatedAt}`: deletes the record (keeping a tombstone
/// so other phones learn about it) unless the server has a newer version.
Future<Response> deleteRecord(
  RequestContext context,
  SyncKind kind,
  String id,
) async {
  final user = await requireUser(context, requireSync: true);
  _checkId(id);
  final body = await readJsonObject(context);
  final updatedAt = DateTime.tryParse(body['updatedAt'] as String? ?? '');
  if (updatedAt == null) {
    throw const ApiException.badRequest('missing_field', {
      'field': 'updatedAt',
    });
  }
  final stored = await context.read<Services>().sync.write(
    user.id,
    kind,
    id,
    null,
    updatedAt,
  );
  return Response.json(body: stored.toJson());
}

/// Ids are UUIDs (created on the phone).
void _checkId(String id) {
  if (!isUuid(id)) throw const ApiException.notFound();
}

/// Checks an own card: it must parse, match the URL id and pass
/// `validateCard`. Images are kept only if hosted by this server, and the
/// share link is managed by the server, never the phone.
(Map<String, Object?>, DateTime) _checkCard(
  Map<String, Object?> json,
  String id,
  Services services,
) {
  final BusinessCard card;
  try {
    card = BusinessCard.fromJson(json);
  } on Object {
    throw const ApiException.badRequest('invalid_card');
  }
  if (card.id != id) throw const ApiException.badRequest('id_mismatch');
  final problems = validateCard(card);
  if (problems.isNotEmpty) {
    throw ApiException(422, 'card_invalid', [
      for (final p in problems) p.name,
    ]);
  }
  final imageBase = services.images.urlFor('').toString();
  String? ownImage(String? url) =>
      url != null && url.startsWith(imageBase) ? url : null;
  final data = card.toJson()
    ..['photoUrl'] = ownImage(card.photoUrl)
    ..['logoUrl'] = ownImage(card.logoUrl)
    ..['shareSlug'] = null;
  return (data, card.updatedAt);
}

/// Checks an Inbox entry: it must parse and match the URL id. Received
/// cards never keep images (DESIGN.md §2).
(Map<String, Object?>, DateTime) _checkReceived(
  Map<String, Object?> json,
  String id,
) {
  final ReceivedCard entry;
  try {
    entry = ReceivedCard.fromJson(json);
  } on Object {
    throw const ApiException.badRequest('invalid_card');
  }
  if (entry.id != id) throw const ApiException.badRequest('id_mismatch');
  final data = entry.toJson();
  (data['card']! as Map<String, Object?>)
    ..['photoUrl'] = null
    ..['logoUrl'] = null;
  return (data, entry.updatedAt);
}
