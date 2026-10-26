// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'eBuCard';

  @override
  String get navMyCards => 'My Cards';

  @override
  String get navExchange => 'Exchange';

  @override
  String get navInbox => 'Inbox';

  @override
  String get newCard => 'New card';

  @override
  String get editCard => 'Edit card';

  @override
  String get myCardsEmpty =>
      'You have no cards yet. Create your first business card.';

  @override
  String get inboxEmpty => 'Cards you receive will appear here.';

  @override
  String get sendSection => 'Share my card';

  @override
  String get receiveSection => 'Receive a card';

  @override
  String get sendByNfc => 'Tap phones (NFC)';

  @override
  String get sendByNfcHint => 'Hold the other phone against the back of yours';

  @override
  String get showQr => 'Show QR code';

  @override
  String get receiveByNfc => 'Read by NFC';

  @override
  String get scanQr => 'Scan QR code';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInWithEmail => 'Continue with email';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get comingSoon => 'Coming soon';
}
