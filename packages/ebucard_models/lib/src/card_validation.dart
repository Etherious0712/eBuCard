import 'business_card.dart';

enum CardValidationError {
  fullNameRequired,
  phoneOrEmailRequired,
  invalidEmail,
}

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
