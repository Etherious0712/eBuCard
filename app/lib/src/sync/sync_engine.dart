// Two-way sync between this phone and the signed-in account
// (server protocol: server/README.md, "Sync protocol").
//
// One run, for own cards and then the Inbox:
//   1. upload images that only exist on this phone and use their URLs,
//   2. send deletions made here,
//   3. send records changed here,
//   4. fetch everything changed on the server since the last run.
// Every record the server returns is applied with "newest wins": a local
// version that is newer than the server's is kept (and sent next time).

import 'package:ebucard_models/ebucard_models.dart';

import '../account/api_client.dart';
import '../data/card_image_service.dart';
import '../data/card_repository.dart';
import '../data/received_card_repository.dart';
import 'local_sync_state.dart';

/// Runs sync. Not thread-safe; `SyncController` makes sure only one run
/// happens at a time.
class SyncEngine {
  /// Creates the engine.
  SyncEngine({
    required this.api,
    required this.cards,
    required this.received,
    required this.state,
    required this.images,
  });

  /// Server access.
  final ApiClient api;

  /// The user's own cards on this phone.
  final CardRepository cards;

  /// The Inbox on this phone.
  final ReceivedCardRepository received;

  /// Cursors and pending deletions.
  final LocalSyncState state;

  /// Local image files.
  final CardImageService images;

  /// One full sync run. Throws [ApiError] if the server can't be reached or
  /// refuses (e.g. `email_not_verified`); what was done so far is kept.
  Future<void> run() async {
    await _uploadLocalImages();
    for (final kind in SyncKind.values) {
      await _pushDeletions(kind);
      await _pushChanges(kind);
      await _pull(kind);
    }
  }

  /// Uploads `file:` photos and logos of changed cards and switches the
  /// cards to the uploaded URLs (the local file is then deleted).
  Future<void> _uploadLocalImages() async {
    for (final card in await cards.dirty()) {
      final json = card.toJson();
      var changed = false;
      for (final field in ['photoUrl', 'logoUrl']) {
        final uri = json[field] as String?;
        if (uri == null || !uri.startsWith('file:')) continue;
        final bytes = await images.readLocal(uri);
        if (bytes == null) continue;
        final uploaded = await api.authed('POST', '/v1/images', bytes: bytes);
        json[field] = uploaded['url'];
        changed = true;
        await images.delete(uri);
      }
      // Same updatedAt: this isn't a new edit, just a new place for images.
      if (changed) await cards.save(BusinessCard.fromJson(json));
    }
  }

  /// Sends deletions made on this phone.
  Future<void> _pushDeletions(SyncKind kind) async {
    for (final deletion in await state.pendingDeletions(kind)) {
      final stored = await api.authed(
        'DELETE',
        '/v1/${kind.path}/${deletion.id}',
        body: {'updatedAt': deletion.deletedAt.toUtc().toIso8601String()},
      );
      await state.forgetDeletion(kind, deletion.id);
      // If the server had a newer edit, that edit wins and comes back.
      await _apply(kind, stored);
    }
  }

  /// Sends records changed on this phone; applies what the server stored.
  Future<void> _pushChanges(SyncKind kind) async {
    final changed = switch (kind) {
      SyncKind.cards => [
        for (final c in await cards.dirty()) (c.id, c.toJson()),
      ],
      SyncKind.received => [
        for (final r in await received.dirty()) (r.id, r.toJson()),
      ],
    };
    for (final (id, json) in changed) {
      try {
        final stored = await api.authed(
          'PUT',
          '/v1/${kind.path}/$id',
          body: json,
        );
        await _apply(kind, stored);
      } on ApiError catch (e) {
        // A record the server can't accept would otherwise block sync
        // forever; skip it and keep going. Other errors stop the run.
        if (e.status != 422 && e.status != 400) rethrow;
      }
    }
  }

  /// Fetches all changes since the last run, page by page.
  Future<void> _pull(SyncKind kind) async {
    var cursor = await state.cursor(kind);
    while (true) {
      final page = await api.authed('GET', '/v1/${kind.path}?since=$cursor');
      for (final change
          in (page['changes']! as List).cast<Map<String, Object?>>()) {
        await _apply(kind, change);
      }
      cursor = page['cursor']! as int;
      await state.setCursor(kind, cursor);
      if (page['hasMore'] != true) break;
    }
  }

  /// Applies one server record (`{id, updatedAt, deleted, data?}`) unless
  /// this phone has something newer for it.
  Future<void> _apply(SyncKind kind, Map<String, Object?> record) async {
    final id = record['id']! as String;
    final serverTime = DateTime.parse(record['updatedAt']! as String);
    final localTime = switch (kind) {
      SyncKind.cards => (await cards.find(id))?.updatedAt,
      SyncKind.received => (await received.find(id))?.updatedAt,
    };
    if (localTime != null && localTime.isAfter(serverTime)) return;
    if (await state.isPendingDeletion(kind, id)) return;

    final data = record['data'] as Map<String, Object?>?;
    if (record['deleted'] == true || data == null) {
      switch (kind) {
        case SyncKind.cards:
          final local = await cards.find(id);
          if (local == null) return;
          await cards.delete(id, fromSync: true);
          await images.delete(local.photoUrl);
          await images.delete(local.logoUrl);
        case SyncKind.received:
          if (localTime != null) await received.delete(id, fromSync: true);
      }
      return;
    }
    switch (kind) {
      case SyncKind.cards:
        await cards.save(BusinessCard.fromJson(data), fromSync: true);
      case SyncKind.received:
        await received.save(ReceivedCard.fromJson(data), fromSync: true);
    }
  }
}
