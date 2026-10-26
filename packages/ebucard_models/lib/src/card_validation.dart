// Rules a card must meet before it can be saved. Shared so the app (editor)
// and the server (API) enforce exactly the same rules.

import 'business_card.dart';

/// A reason a card can't be saved yet. The app maps each to a message.
enum CardValidationError {
  /// [BusinessCard.fullName] is empty or only whitespace.
  fullNameRequired,

  /// The card has no non-blank phone number and no non-blank email.
  phoneOrEmailRequired,

  /// At least one non-blank email doesn't look like an email address.
  invalidEmail,
}

/// `something@something.tld` with no spaces; deliberately loose.
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Basic shape check (`name@domain.tld`); not a full RFC 5322 parser.
bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

/// Checks the rules a card must meet before it can be saved: a full name and
/// at least one phone number or email address. Blank entries are ignored.
Set<CardValidationError> validateCard(BusinessCard card) {
  final phones = card.phones.where((p) => p.value.trim().isNotEmpty);
  final emails = card.emails.where((e) => e.value.trim().isNotEmpty);
  return {
    if (card.fullName.trim().isEmpty) CardValidationError.fullNameRequired,
    if (phones.isEmpty && emails.isEmpty)
      CardValidationError.phoneOrEmailRequired,
    if (emails.any((e) => !isValidEmail(e.value)))
      CardValidationError.invalidEmail,
  };
}
