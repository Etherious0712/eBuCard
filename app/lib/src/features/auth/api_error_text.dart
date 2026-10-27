// Turns server error codes (server/README.md) into messages people can read.

import '../../account/api_client.dart';
import '../../l10n/generated/app_localizations.dart';

/// The message for [error] in the current language.
String apiErrorText(AppLocalizations l10n, Object error) =>
    apiErrorCodeText(l10n, error is ApiError ? error.code : '');

/// The message for a server error [code] (e.g. the last sync error).
String apiErrorCodeText(AppLocalizations l10n, String code) {
  return switch (code) {
    'network' => l10n.errorNetwork,
    'invalid_credentials' => l10n.errorInvalidCredentials,
    'email_taken' => l10n.errorEmailTaken,
    'invalid_email' => l10n.errorInvalidEmail,
    'password_too_short' || 'password_too_long' => l10n.errorPasswordTooShort,
    'password_breached' => l10n.errorPasswordBreached,
    'too_many_requests' => l10n.errorTooManyRequests,
    'email_not_verified' => l10n.emailNotConfirmed,
    _ => l10n.errorGeneric,
  };
}
