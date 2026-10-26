// Turns a BusinessCard into vCard text, the standard contact format that phone
// Contacts apps import. This is what is sent over NFC and in offline QR codes.

import 'business_card.dart';

/// Encodes a [BusinessCard] as vCard 3.0 (RFC 2426).
///
/// vCard 3.0 is used rather than 4.0 because it is the version imported most
/// reliably by both Android Contacts and iOS Contacts.
class VCardEncoder {
  /// Creates an encoder. It holds no state, so one instance can be shared.
  const VCardEncoder();

  /// Full vCard including addresses and social links. Photo/logo are referenced
  /// by URL only; images are never embedded so payloads stay small.
  String encode(BusinessCard card) => _encode(card, compact: false);

  /// Minimal vCard (name, title, company, first phone/email, card URL) that
  /// fits comfortably in an NFC NDEF record or a scannable QR code.
  String encodeCompact(BusinessCard card, {Uri? cardUrl}) =>
      _encode(card, compact: true, cardUrl: cardUrl);

  /// Builds the vCard lines shared by [encode] and [encodeCompact], then
  /// folds long lines and joins them with CRLF as RFC 2426 requires.
  String _encode(BusinessCard card, {required bool compact, Uri? cardUrl}) {
    // Identity: always present.
    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN:${_escape(card.fullName)}',
      'N:${_structuredName(card.fullName)}',
      if (card.company.isNotEmpty) 'ORG:${_escape(card.company)}',
      if (card.jobTitle.isNotEmpty) 'TITLE:${_escape(card.jobTitle)}',
    ];

    // Contact details: compact form keeps only the first of each.
    final phones = compact ? card.phones.take(1) : card.phones;
    for (final p in phones) {
      lines.add('TEL;TYPE=${_telType(p.label)}:${_escape(p.value)}');
    }
    final emails = compact ? card.emails.take(1) : card.emails;
    for (final e in emails) {
      lines.add(
        'EMAIL;TYPE=INTERNET,${_labelType(e.label)}:${_escape(e.value)}',
      );
    }

    if (cardUrl != null) lines.add('URL:${_escape(cardUrl.toString())}');

    // Everything else is only in the full form.
    if (!compact) {
      for (final w in card.websites) {
        lines.add('URL:${_escape(w)}');
      }
      for (final a in card.addresses) {
        final parts = [
          '', // PO box
          '', // extended address
          a.street,
          a.city,
          a.region,
          a.postalCode,
          a.country,
        ].map(_escape).join(';');
        lines.add('ADR;TYPE=${_labelType(a.label)}:$parts');
      }
      for (final s in card.socialLinks) {
        lines.add(
          'X-SOCIALPROFILE;TYPE=${s.network.name}:${_escape(s.handleOrUrl)}',
        );
      }
      final photo = _remoteUri(card.photoUrl);
      if (photo != null) lines.add('PHOTO;VALUE=URI:$photo');
      final logo = _remoteUri(card.logoUrl);
      if (logo != null) lines.add('LOGO;VALUE=URI:$logo');
    }

    lines.add('END:VCARD');
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  /// Only http(s) image URLs are shared; local `file:` paths stay on device.
  static String? _remoteUri(String? value) {
    if (value == null) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    return value;
  }

  /// Best-effort split of a display name into "family;given". Users can enter
  /// names in any order/script, so this never drops characters.
  static String _structuredName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return '${_escape(fullName.trim())};;;;';
    final family = parts.last;
    final given = parts.sublist(0, parts.length - 1).join(' ');
    return '${_escape(family)};${_escape(given)};;;';
  }

  /// vCard TYPE for a phone number (`CELL`, `FAX`, `WORK`, ...).
  static String _telType(ContactLabel label) => switch (label) {
    ContactLabel.mobile => 'CELL',
    ContactLabel.fax => 'FAX',
    _ => _labelType(label),
  };

  /// vCard TYPE for an email or address label.
  static String _labelType(ContactLabel label) => switch (label) {
    ContactLabel.work => 'WORK',
    ContactLabel.home => 'HOME',
    ContactLabel.mobile => 'CELL',
    ContactLabel.fax => 'FAX',
    ContactLabel.other => 'OTHER',
  };

  /// Escapes characters that have a meaning in vCard values
  /// (backslash, newline, comma, semicolon).
  static String _escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('\n', r'\n')
      .replaceAll(',', r'\,')
      .replaceAll(';', r'\;');

  /// Folds lines longer than 75 octets per RFC 2426 §2.6, without splitting
  /// a UTF-8 multi-byte character.
  static String _fold(String line) {
    const limit = 75;
    final buffer = StringBuffer();
    var octets = 0;
    for (final rune in line.runes) {
      final char = String.fromCharCode(rune);
      final size = _utf8Length(rune);
      if (octets + size > limit) {
        buffer.write('\r\n ');
        octets = 1;
      }
      buffer.write(char);
      octets += size;
    }
    return buffer.toString();
  }

  /// Number of bytes [rune] takes in UTF-8 (1 to 4).
  static int _utf8Length(int rune) {
    if (rune < 0x80) return 1;
    if (rune < 0x800) return 2;
    if (rune < 0x10000) return 3;
    return 4;
  }
}
