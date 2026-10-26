// Tap-to-act on a received card: call a number, write an email, open a site.

import 'package:url_launcher/url_launcher.dart';

/// Opens phone numbers, email addresses and websites in other apps.
abstract class LinkLauncher {
  /// Opens [uri] in the app that handles it. Returns false if no app can.
  Future<bool> open(Uri uri);

  /// `tel:` link for [phone], keeping only `+` and digits.
  static Uri phone(String phone) =>
      Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));

  /// `mailto:` link for [email].
  static Uri email(String email) => Uri(scheme: 'mailto', path: email.trim());

  /// Web link for [website]; adds `https://` when the scheme is missing.
  static Uri website(String website) {
    final trimmed = website.trim();
    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed);
    return Uri.parse(hasScheme ? trimmed : 'https://$trimmed');
  }
}

/// The real [LinkLauncher], using url_launcher.
class DeviceLinkLauncher implements LinkLauncher {
  @override
  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
