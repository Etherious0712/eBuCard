// Public card links (`/c/<slug>`, DESIGN.md §4.1). The server owns each
// card's slug: it creates one when the card first syncs, and the owner can
// revoke it or swap it for a new one. A revoked or replaced slug stops
// working at once; cards people already received keep their snapshot.

import 'dart:math';

import 'package:ebucard_server/src/http/api_error.dart';
import 'package:ebucard_server/src/sync/sync_store.dart';
import 'package:postgres/postgres.dart';

const _alphabet =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

/// A new random slug: 22 base62 characters (about 131 bits), so links
/// can't be guessed or listed.
String newShareSlug([Random? random]) {
  final r = random ?? Random.secure();
  return String.fromCharCodes([
    for (var i = 0; i < 22; i++) _alphabet.codeUnitAt(r.nextInt(62)),
  ]);
}

/// Whether [slug] looks like one made by [newShareSlug]. Anything else is
/// a 404 without a database lookup.
bool isShareSlug(String slug) => RegExp(r'^[0-9A-Za-z]{22}$').hasMatch(slug);

/// A card shown through its public link.
class PublicCard {
  /// Creates a public card.
  const PublicCard(this.data, this.updatedAt);

  /// The card JSON (with its `shareSlug`).
  final Map<String, Object?> data;

  /// When the owner last changed it.
  final DateTime updatedAt;
}

/// Creates, revokes and looks up card links.
class ShareLinks {
  /// Creates the store over [_db].
  ShareLinks(this._db);

  final Pool<void> _db;

  /// Gives card [cardId] of [userId] a new link (the old one stops
  /// working) and returns the card record, so the phone can store it.
  Future<SyncRecord> regenerate(String userId, String cardId) =>
      _setSlug(userId, cardId, newShareSlug());

  /// Ends the link of card [cardId]. No new link is made on later syncs
  /// until [regenerate] is called.
  Future<SyncRecord> revoke(String userId, String cardId) =>
      _setSlug(userId, cardId, null);

  /// Sets the slug and moves the card to the end of the change list, so
  /// the user's other phones learn about it on their next sync.
  Future<SyncRecord> _setSlug(
    String userId,
    String cardId,
    String? slug,
  ) async {
    final rows = await _db.execute(
      Sql.named(
        'UPDATE cards SET share_slug = @slug::text, '
        "link_revoked = @revoked, seq = nextval('sync_seq') "
        'WHERE id = @id::uuid AND user_id = @user::uuid AND NOT deleted '
        'RETURNING ${SyncRecord.columns(SyncKind.cards)}',
      ),
      parameters: {
        'slug': slug,
        'revoked': slug == null,
        'id': cardId,
        'user': userId,
      },
    );
    if (rows.isEmpty) throw const ApiException.notFound();
    return SyncRecord.fromRow(rows.first.toColumnMap());
  }

  /// The card behind [slug], or null if the link doesn't exist, was
  /// revoked, or the owner's account is being deleted.
  Future<PublicCard?> find(String slug) async {
    if (!isShareSlug(slug)) return null;
    final rows = await _db.execute(
      Sql.named(
        "SELECT c.data || jsonb_build_object('shareSlug', c.share_slug) "
        'AS data, c.updated_at FROM cards c JOIN users u ON u.id = c.user_id '
        'WHERE c.share_slug = @slug AND NOT c.deleted '
        'AND u.deactivated_at IS NULL',
      ),
      parameters: {'slug': slug},
    );
    if (rows.isEmpty) return null;
    final row = rows.first.toColumnMap();
    return PublicCard(
      Map<String, Object?>.from(row['data']! as Map),
      row['updated_at']! as DateTime,
    );
  }
}
