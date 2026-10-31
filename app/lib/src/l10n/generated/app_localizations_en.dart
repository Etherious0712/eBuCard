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

  @override
  String get nfcShareTitle => 'Tap phones (NFC)';

  @override
  String get nfcShareReady => 'Ready to share';

  @override
  String get nfcShareHint =>
      'Keep this screen open and hold the back of your phone against the other phone. On their phone: eBuCard → Exchange → Read by NFC.';

  @override
  String get nfcCannotShare =>
      'This phone can\'t share by NFC. Show your QR code instead.';

  @override
  String get nfcUnsupported =>
      'This phone doesn\'t have NFC. Use a QR code instead.';

  @override
  String get nfcOff => 'NFC is off';

  @override
  String get nfcOffMessage =>
      'Turn on NFC to exchange cards by tapping phones. You can use a QR code meanwhile.';

  @override
  String get openNfcSettings => 'Open NFC settings';

  @override
  String get useQrInstead => 'Use QR code instead';

  @override
  String get nfcReceiveTitle => 'Read by NFC';

  @override
  String get nfcReceiveListening =>
      'Hold your phone against the back of the other phone';

  @override
  String get nfcReceiveHint =>
      'On their phone: eBuCard → Exchange → Tap phones (NFC). iPhones can\'t share by NFC: ask them to show their QR code.';

  @override
  String get nfcIosAlert => 'Hold your iPhone near the other phone.';

  @override
  String get nfcIosSuccess => 'Card received';

  @override
  String get nfcStopped => 'Stopped listening.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get nfcNotACard => 'The other phone didn\'t share a business card.';

  @override
  String get account => 'Account';

  @override
  String get signInIntro =>
      'Signing in is optional. It backs up your cards and Inbox and keeps them the same on all your phones.';

  @override
  String get createAccount => 'Create account';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'At least 8 characters';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordMessage =>
      'We\'ll email you a link to choose a new password.';

  @override
  String get send => 'Send';

  @override
  String get resetEmailSent =>
      'If an account uses that email, a reset link is on its way.';

  @override
  String get orContinueWith => 'or';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutMessage =>
      'Your cards and Inbox will be removed from this phone. They stay safe in your account.';

  @override
  String get signOutUnsynced =>
      'Some changes haven\'t reached your account yet (no connection). If you sign out now, they are lost.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountMessage =>
      'You\'ll be signed out everywhere. Your account, cards, Inbox and photos are erased after 30 days. Signing in again before then cancels the deletion.';

  @override
  String get emailConfirmed => 'Email confirmed';

  @override
  String get emailNotConfirmed =>
      'Confirm your email to turn on sync. We sent you a link.';

  @override
  String get resendEmail => 'Send the email again';

  @override
  String get emailResent => 'Email sent';

  @override
  String get iConfirmed => 'I\'ve confirmed it';

  @override
  String get signedInWithApple => 'Signed in with Apple';

  @override
  String get signedInWithGoogle => 'Signed in with Google';

  @override
  String get syncSection => 'Sync';

  @override
  String get syncing => 'Syncing…';

  @override
  String syncedAt(String time) {
    return 'Synced $time';
  }

  @override
  String get notSyncedYet => 'Not synced yet';

  @override
  String get syncNow => 'Sync now';

  @override
  String get sessionExpired =>
      'You were signed out. Sign in again to keep syncing.';

  @override
  String get errorNetwork =>
      'Can\'t reach eBuCard. Check your connection and try again.';

  @override
  String get errorInvalidCredentials => 'Wrong email or password.';

  @override
  String get errorEmailTaken =>
      'An account with this email already exists. Sign in instead.';

  @override
  String get errorPasswordTooShort => 'Use at least 8 characters.';

  @override
  String get errorPasswordBreached =>
      'This password has appeared in a data breach. Please choose another one.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Please wait a few minutes.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get showQrLinkHint =>
      'Anyone can scan this with their phone camera to open your card, even without eBuCard.';

  @override
  String get offlineQr => 'Offline QR';

  @override
  String get offlineQrHint =>
      'Puts the whole card in the code, so it works without internet. Photo and logo aren\'t included.';

  @override
  String get linkTitle => 'Card link';

  @override
  String get linkSignInHint =>
      'Sign in to get a link to this card that anyone can open, even without the app.';

  @override
  String get linkConfirmEmailHint =>
      'Confirm your email to turn on sync and card links.';

  @override
  String get linkNone => 'This card has no link right now.';

  @override
  String get linkMake => 'Make a link';

  @override
  String get linkHint =>
      'Share this link anywhere. It always shows your latest card.';

  @override
  String get linkCopy => 'Copy';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get linkNew => 'New link';

  @override
  String get linkNewTitle => 'Make a new link?';

  @override
  String get linkNewMessage =>
      'The current link stops working. People who already saved your card keep it.';

  @override
  String get linkOff => 'Turn off';

  @override
  String get linkOffTitle => 'Turn off this link?';

  @override
  String get linkOffMessage =>
      'The link stops working at once. QR codes and NFC will share the full card instead. You can make a new link later.';

  @override
  String get linkSyncFirst =>
      'This card hasn\'t synced yet. Try again in a moment.';

  @override
  String get linkInactive =>
      'This card link is no longer active. Ask for the card again.';

  @override
  String get linkOffline =>
      'Couldn\'t open the card link. Check your connection and try again.';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get cardUpToDate => 'This card is up to date';

  @override
  String get openingCard => 'Opening card…';

  @override
  String get showQrOfflineLinkHint =>
      'Anyone can scan this with their phone camera to see your card and save it, even without eBuCard. eBuCard users don\'t need internet.';

  @override
  String get fullVcardQr => 'Full vCard in the code';

  @override
  String get fullVcardQrHint =>
      'The camera opens the phone\'s new-contact screen directly instead of a web card.';

  @override
  String get offlineLinkHint =>
      'Send this link in any chat or email. Your card is inside the link itself, so later edits don\'t change links you\'ve already shared.';
}
