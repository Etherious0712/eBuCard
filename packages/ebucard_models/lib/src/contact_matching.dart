// Decides whether two cards belong to the same person, so scanning someone
// twice can offer to update their Inbox entry instead of duplicating it.

import 'business_card.dart';

/// True if [a] and [b] look like the same person: the same name (ignoring
/// case and spacing) and at least one phone number or email in common.
///
/// Phone numbers match on digits only, and a number with a country code
/// matches the same number without it (`+852 9123 4567` = `91234567`), as
/// long as at least 8 digits match.
bool isSamePerson(BusinessCard a, BusinessCard b) {
  if (_normalizeName(a.fullName) != _normalizeName(b.fullName)) return false;

  final emailsA = a.emails.map((e) => e.value.trim().toLowerCase()).toSet();
  if (b.emails.any((e) => emailsA.contains(e.value.trim().toLowerCase()))) {
    return true;
  }

  final phonesA = a.phones.map((p) => _digits(p.value)).where(_longEnough);
  final phonesB = b.phones.map((p) => _digits(p.value)).where(_longEnough);
  return phonesA.any((x) => phonesB.any((y) => _samePhone(x, y)));
}

/// Lower case with runs of whitespace collapsed.
String _normalizeName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Only the digits of a phone number.
String _digits(String phone) => phone.replaceAll(RegExp(r'\D'), '');

/// Shorter numbers (extensions, short codes) are too ambiguous to match.
bool _longEnough(String digits) => digits.length >= 8;

/// Same number, or one is the other with a country code in front.
bool _samePhone(String x, String y) => x.endsWith(y) || y.endsWith(x);
