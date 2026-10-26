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

  @override
  String get cardName => 'Card name';

  @override
  String get cardNameHint => 'e.g. Work, Personal';

  @override
  String get defaultCardName => 'My card';

  @override
  String get profileSection => 'Profile';

  @override
  String get contactSection => 'Contact';

  @override
  String get fullName => 'Full name';

  @override
  String get jobTitle => 'Job title';

  @override
  String get company => 'Company';

  @override
  String get phones => 'Phone numbers';

  @override
  String get emails => 'Email addresses';

  @override
  String get websites => 'Websites';

  @override
  String get addresses => 'Addresses';

  @override
  String get socialLinks => 'Social links';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get website => 'Website';

  @override
  String get addPhone => 'Add phone';

  @override
  String get addEmail => 'Add email';

  @override
  String get addWebsite => 'Add website';

  @override
  String get addAddress => 'Add address';

  @override
  String get addSocialLink => 'Add social link';

  @override
  String get street => 'Street';

  @override
  String get city => 'City';

  @override
  String get region => 'State / region';

  @override
  String get postalCode => 'Postal code';

  @override
  String get country => 'Country';

  @override
  String get handleOrUrl => 'Username or link';

  @override
  String get labelWork => 'Work';

  @override
  String get labelMobile => 'Mobile';

  @override
  String get labelHome => 'Home';

  @override
  String get labelFax => 'Fax';

  @override
  String get labelOther => 'Other';

  @override
  String get photo => 'Photo';

  @override
  String get logo => 'Logo';

  @override
  String get cropImage => 'Crop image';

  @override
  String get chooseFromGallery => 'Choose from library';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get removeImage => 'Remove';

  @override
  String get remove => 'Remove';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteCardTitle => 'Delete this card?';

  @override
  String get deleteCardMessage => 'This card will be removed from this device.';

  @override
  String get cardSaved => 'Card saved';

  @override
  String get cardNotFound => 'This card no longer exists.';

  @override
  String get errorFullNameRequired => 'Enter a full name';

  @override
  String get errorPhoneOrEmailRequired =>
      'Add at least one phone number or email address';

  @override
  String get errorInvalidEmail => 'Enter a valid email address';

  @override
  String get errorImage => 'Couldn\'t load the image. Please try again.';

  @override
  String get socialOther => 'Other';

  @override
  String get showQrTitle => 'My QR code';

  @override
  String get showQrHint =>
      'Ask the other person to scan this with eBuCard or their phone\'s camera.';

  @override
  String get showQrNoCards =>
      'Create a card first, then you can share it here.';

  @override
  String get createCard => 'Create card';

  @override
  String get qrTooLarge =>
      'This card has too much information for one QR code. Remove some fields and try again.';

  @override
  String get showingCard => 'Card to share';

  @override
  String get setAsDefault => 'Set as default card';

  @override
  String get isDefaultCard => 'Default card';

  @override
  String get defaultCardSet => 'Default card updated';

  @override
  String get scanHint => 'Point the camera at an eBuCard or contact QR code.';

  @override
  String get notACard => 'This QR code isn\'t a business card.';

  @override
  String get cameraError =>
      'Can\'t use the camera. Allow eBuCard to use the camera in Settings.';

  @override
  String get duplicateTitle => 'Already in your Inbox';

  @override
  String duplicateMessage(String name) {
    return '$name is already in your Inbox. Update the saved card, or keep both?';
  }

  @override
  String get update => 'Update';

  @override
  String get keepBoth => 'Keep both';

  @override
  String get cardReceived => 'Card added to your Inbox';

  @override
  String get cardUpdated => 'Card updated';

  @override
  String get searchInbox => 'Search name, company or email';

  @override
  String get inboxNoMatches => 'No matching cards';

  @override
  String receivedOn(String date) {
    return 'Received $date';
  }

  @override
  String get note => 'Private note';

  @override
  String get noteHint => 'Only you can see this, e.g. where you met';

  @override
  String get saveNote => 'Save note';

  @override
  String get noteSaved => 'Note saved';

  @override
  String get saveToContacts => 'Save to Contacts';

  @override
  String get contactsError => 'Couldn\'t open Contacts.';

  @override
  String get cantOpenLink => 'No app on this phone can open this.';

  @override
  String get deleteReceivedTitle => 'Remove this card from your Inbox?';

  @override
  String get deleteReceivedMessage =>
      'It is only removed from eBuCard, not from your phone\'s Contacts.';
}
