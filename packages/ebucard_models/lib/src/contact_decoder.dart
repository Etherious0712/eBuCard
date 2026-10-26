// Reads contact data from a scanned QR code (or, later, an NFC tag) and turns
// it into a BusinessCard. Accepts vCard 2.1, 3.0 and 4.0 (what eBuCard and
// most phones produce) and MECARD (common on printed business cards).

import 'dart:convert';

import 'business_card.dart';

/// Turns contact text from a QR code or NFC tag into a [BusinessCard].
///
/// Images (PHOTO, LOGO) in received data are ignored on purpose: embedded
/// images are too large to store per contact, and loading a remote image
/// chosen by a stranger would tell them when the card was opened.
class ContactDecoder {
  /// Creates a decoder. It holds no state, so one instance can be shared.
  const ContactDecoder();

  /// Parses [text] into a card with the given [id], stamped [now].
  ///
  /// Returns null if [text] is not a vCard or MECARD, or if it has no name,
  /// company, phone number or email at all. The card's `cardName` is empty:
  /// that field only means something for the user's own cards.
  BusinessCard? decode(
    String text, {
    required String id,
    required DateTime now,
  }) {
    final trimmed = text.trim();
    final fields = trimmed.toUpperCase().startsWith('MECARD:')
        ? _parseMecard(trimmed)
        : _parseVCard(trimmed);
    if (fields == null) return null;
    return fields.toCard(id: id, now: now);
  }

  // ---------------------------------------------------------------- vCard --

  /// Parses the first `BEGIN:VCARD` … `END:VCARD` block in [text].
  _Fields? _parseVCard(String text) {
    final lines = _unfold(text);
    final start = lines.indexWhere((l) => l.toUpperCase() == 'BEGIN:VCARD');
    if (start == -1) return null;
    final fields = _Fields();
    for (final line in lines.skip(start + 1)) {
      if (line.toUpperCase() == 'END:VCARD') return fields;
      final property = _Property.parse(line);
      if (property != null) _applyVCardProperty(fields, property);
    }
    return null; // No END:VCARD: truncated or not a vCard.
  }

  /// Joins folded lines back together.
  ///
  /// A line starting with a space or tab continues the previous one
  /// (RFC 2425). In vCard 2.1 quoted-printable values, a line ending in `=`
  /// also continues on the next line.
  static List<String> _unfold(String text) {
    final raw = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final lines = <String>[];
    for (final line in raw) {
      if (lines.isNotEmpty && (line.startsWith(' ') || line.startsWith('\t'))) {
        lines.last += line.substring(1);
      } else if (lines.isNotEmpty &&
          lines.last.toUpperCase().contains('QUOTED-PRINTABLE') &&
          lines.last.endsWith('=')) {
        lines.last = lines.last.substring(0, lines.last.length - 1) + line;
      } else if (line.isNotEmpty) {
        lines.add(line);
      }
    }
    return lines;
  }

  /// Copies one vCard property into [fields].
  static void _applyVCardProperty(_Fields fields, _Property p) {
    switch (p.name) {
      case 'FN':
        fields.formattedName = _unescape(p.value);
      case 'N':
        // family;given;additional;prefix;suffix
        final parts = _splitStructured(p.value);
        String part(int i) => i < parts.length ? parts[i] : '';
        fields.structuredName = [
          part(3),
          part(1),
          part(2),
          part(0),
          part(4),
        ].where((s) => s.isNotEmpty).join(' ');
      case 'ORG':
        fields.company = _splitStructured(p.value).first;
      case 'TITLE':
        fields.jobTitle = _unescape(p.value);
      case 'TEL':
        var value = _unescape(p.value);
        if (value.toLowerCase().startsWith('tel:')) value = value.substring(4);
        if (value.isNotEmpty) {
          fields.phones.add(
            LabeledValue(label: _phoneLabel(p.types), value: value),
          );
        }
      case 'EMAIL':
        final value = _unescape(p.value);
        if (value.isNotEmpty) {
          fields.emails.add(LabeledValue(label: _label(p.types), value: value));
        }
      case 'URL':
        final value = _unescape(p.value);
        if (value.isNotEmpty) fields.websites.add(value);
      case 'ADR':
        // pobox;extended;street;city;region;postal code;country
        final parts = _splitStructured(p.value);
        String part(int i) => i < parts.length ? parts[i] : '';
        final address = PostalAddress(
          label: _label(p.types),
          street: [
            part(0),
            part(1),
            part(2),
          ].where((s) => s.isNotEmpty).join(', '),
          city: part(3),
          region: part(4),
          postalCode: part(5),
          country: part(6),
        );
        if (parts.any((s) => s.isNotEmpty)) fields.addresses.add(address);
      case 'X-SOCIALPROFILE':
        final value = _unescape(p.value);
        if (value.isNotEmpty) {
          fields.socialLinks.add(
            SocialLink(network: _network(p.types), handleOrUrl: value),
          );
        }
    }
  }

  /// Maps vCard TEL types to a [ContactLabel]; "cell" wins over "work".
  static ContactLabel _phoneLabel(Set<String> types) {
    if (types.contains('cell') || types.contains('mobile')) {
      return ContactLabel.mobile;
    }
    if (types.contains('fax')) return ContactLabel.fax;
    return _label(types);
  }

  /// Maps vCard types to work / home / other.
  static ContactLabel _label(Set<String> types) {
    if (types.contains('work')) return ContactLabel.work;
    if (types.contains('home')) return ContactLabel.home;
    return ContactLabel.other;
  }

  /// Maps an X-SOCIALPROFILE type (e.g. `linkedin`) to a [SocialNetwork].
  static SocialNetwork _network(Set<String> types) {
    for (final n in SocialNetwork.values) {
      if (types.contains(n.name)) return n;
    }
    if (types.contains('twitter')) return SocialNetwork.x;
    return SocialNetwork.other;
  }

  /// Splits a structured value (N, ADR, ORG) on unescaped `;` and unescapes
  /// each part.
  static List<String> _splitStructured(String value) {
    final parts = <String>[];
    final current = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final c = value[i];
      if (c == r'\' && i + 1 < value.length) {
        current
          ..write(c)
          ..write(value[++i]);
      } else if (c == ';') {
        parts.add(_unescape(current.toString()));
        current.clear();
      } else {
        current.write(c);
      }
    }
    parts.add(_unescape(current.toString()));
    return parts;
  }

  /// Reverses vCard escaping: `\n`, `\,`, `\;`, `\\`.
  static String _unescape(String value) {
    final out = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final c = value[i];
      if (c == r'\' && i + 1 < value.length) {
        final next = value[++i];
        out.write(next == 'n' || next == 'N' ? '\n' : next);
      } else {
        out.write(c);
      }
    }
    return out.toString().trim();
  }

  // --------------------------------------------------------------- MECARD --

  /// Parses `MECARD:N:Family,Given;TEL:...;EMAIL:...;;`.
  static _Fields? _parseMecard(String text) {
    final body = text.substring('MECARD:'.length);
    final fields = _Fields();
    for (final entry in _splitMecard(body)) {
      final colon = entry.indexOf(':');
      if (colon <= 0) continue;
      final key = entry.substring(0, colon).toUpperCase();
      final value = entry.substring(colon + 1).trim();
      if (value.isEmpty) continue;
      switch (key) {
        case 'N':
          // "Family,Given" → "Given Family".
          final parts = value.split(',').map((s) => s.trim()).toList();
          fields.structuredName = parts.reversed
              .where((s) => s.isNotEmpty)
              .join(' ');
        case 'ORG':
          fields.company = value;
        case 'TITLE':
          fields.jobTitle = value;
        case 'TEL':
          fields.phones.add(
            LabeledValue(label: ContactLabel.other, value: value),
          );
        case 'EMAIL':
          fields.emails.add(
            LabeledValue(label: ContactLabel.other, value: value),
          );
        case 'URL':
          fields.websites.add(value);
        case 'ADR':
          fields.addresses.add(
            PostalAddress(label: ContactLabel.other, street: value),
          );
      }
    }
    return fields;
  }

  /// Splits MECARD fields on unescaped `;`, removing `\` escapes.
  static List<String> _splitMecard(String body) {
    final entries = <String>[];
    final current = StringBuffer();
    for (var i = 0; i < body.length; i++) {
      final c = body[i];
      if (c == r'\' && i + 1 < body.length) {
        current.write(body[++i]);
      } else if (c == ';') {
        entries.add(current.toString());
        current.clear();
      } else {
        current.write(c);
      }
    }
    if (current.isNotEmpty) entries.add(current.toString());
    return entries;
  }
}

/// One parsed vCard content line: `group.NAME;PARAM=a,b;PARAM:value`.
class _Property {
  _Property(this.name, this.types, this.value);

  /// Property name in upper case, without any `group.` prefix.
  final String name;

  /// Lower-case TYPE values, including vCard 2.1 bare types (`;WORK;CELL`).
  final Set<String> types;

  /// The value, already decoded from quoted-printable / base64 text if the
  /// parameters said so, but still vCard-escaped.
  final String value;

  /// Parses [line], or returns null if it has no `:`.
  static _Property? parse(String line) {
    final colon = _valueColon(line);
    if (colon == -1) return null;
    final head = line.substring(0, colon).split(';');
    var value = line.substring(colon + 1);
    var name = head.first.toUpperCase();
    final dot = name.lastIndexOf('.');
    if (dot != -1) name = name.substring(dot + 1);

    final types = <String>{};
    var quotedPrintable = false;
    for (final param in head.skip(1)) {
      final eq = param.indexOf('=');
      final key = eq == -1 ? 'TYPE' : param.substring(0, eq).toUpperCase();
      final values = (eq == -1 ? param : param.substring(eq + 1))
          .replaceAll('"', '')
          .toLowerCase()
          .split(',');
      if (key == 'TYPE') types.addAll(values);
      if ((key == 'ENCODING' || key == 'TYPE') &&
          values.contains('quoted-printable')) {
        quotedPrintable = true;
      }
    }
    if (quotedPrintable) value = _decodeQuotedPrintable(value);
    return _Property(name, types, value);
  }

  /// Index of the `:` that starts the value, skipping colons inside quoted
  /// parameter values.
  static int _valueColon(String line) {
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      if (line[i] == '"') quoted = !quoted;
      if (line[i] == ':' && !quoted) return i;
    }
    return -1;
  }

  /// Decodes `=E9=99=B3` style quoted-printable text as UTF-8.
  static String _decodeQuotedPrintable(String value) {
    final bytes = <int>[];
    for (var i = 0; i < value.length; i++) {
      final c = value[i];
      if (c == '=' && i + 2 < value.length) {
        final hex = int.tryParse(value.substring(i + 1, i + 3), radix: 16);
        if (hex != null) {
          bytes.add(hex);
          i += 2;
          continue;
        }
      }
      bytes.addAll(utf8.encode(c));
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}

/// Values collected while parsing, before they become a [BusinessCard].
class _Fields {
  /// vCard FN, the name exactly as the sender formatted it.
  String formattedName = '';

  /// Name assembled from vCard N or MECARD N parts ("Given Family").
  String structuredName = '';
  String company = '';
  String jobTitle = '';
  final phones = <LabeledValue>[];
  final emails = <LabeledValue>[];
  final websites = <String>[];
  final addresses = <PostalAddress>[];
  final socialLinks = <SocialLink>[];

  /// Builds the card. The display name falls back from FN to N, then to the
  /// company, email or phone, so every received card has something to show.
  /// Returns null if there is nothing to identify the person by.
  BusinessCard? toCard({required String id, required DateTime now}) {
    final name = [
      formattedName,
      structuredName,
      company,
      if (emails.isNotEmpty) emails.first.value,
      if (phones.isNotEmpty) phones.first.value,
    ].firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
    if (name.isEmpty) return null;
    return BusinessCard(
      id: id,
      cardName: '',
      fullName: name.trim(),
      jobTitle: jobTitle,
      company: company,
      phones: phones,
      emails: emails,
      websites: websites,
      addresses: addresses,
      socialLinks: socialLinks,
      updatedAt: now.toUtc(),
    );
  }
}
