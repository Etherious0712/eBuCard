// A card someone else gave the user, as stored in their Inbox.

import 'business_card.dart';

/// How a card reached the user.
enum ReceivedVia {
  /// Scanned from a QR code.
  qr,

  /// Read from another phone over NFC.
  nfc,

  /// Opened from a card link (`/c/<slug>`).
  link,
}

/// A card in the user's Inbox: a snapshot of the other person's card plus
/// the user's own private data about it (never shared).
class ReceivedCard {
  /// Creates an Inbox entry.
  const ReceivedCard({
    required this.id,
    required this.card,
    required this.receivedVia,
    required this.receivedAt,
    this.note = '',
    required this.updatedAt,
  });

  /// Stable unique ID of this Inbox entry (a UUID).
  final String id;

  /// The other person's card as it was received. Its `cardName` is empty.
  final BusinessCard card;

  /// How the card arrived.
  final ReceivedVia receivedVia;

  /// When the card was first received (UTC). Kept when the card is updated
  /// by scanning the same person again.
  final DateTime receivedAt;

  /// The user's private note, e.g. "Met at Expo 2026". Never shared.
  final String note;

  /// When this entry last changed (UTC), for sync.
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  ReceivedCard copyWith({
    BusinessCard? card,
    ReceivedVia? receivedVia,
    String? note,
    DateTime? updatedAt,
  }) => ReceivedCard(
    id: id,
    card: card ?? this.card,
    receivedVia: receivedVia ?? this.receivedVia,
    receivedAt: receivedAt,
    note: note ?? this.note,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Encodes this entry as JSON.
  Map<String, Object?> toJson() => {
    'id': id,
    'card': card.toJson(),
    'receivedVia': receivedVia.name,
    'receivedAt': receivedAt.toUtc().toIso8601String(),
    'note': note,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  /// Decodes an entry written by [toJson].
  factory ReceivedCard.fromJson(Map<String, Object?> json) => ReceivedCard(
    id: json['id']! as String,
    card: BusinessCard.fromJson(json['card']! as Map<String, Object?>),
    receivedVia: ReceivedVia.values.byName(json['receivedVia']! as String),
    receivedAt: DateTime.parse(json['receivedAt']! as String),
    note: json['note'] as String? ?? '',
    updatedAt: DateTime.parse(json['updatedAt']! as String),
  );
}
