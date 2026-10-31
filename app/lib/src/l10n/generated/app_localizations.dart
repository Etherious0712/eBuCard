import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'eBuCard'**
  String get appTitle;

  /// No description provided for @navMyCards.
  ///
  /// In en, this message translates to:
  /// **'My Cards'**
  String get navMyCards;

  /// No description provided for @navExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get navExchange;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// No description provided for @newCard.
  ///
  /// In en, this message translates to:
  /// **'New card'**
  String get newCard;

  /// No description provided for @editCard.
  ///
  /// In en, this message translates to:
  /// **'Edit card'**
  String get editCard;

  /// No description provided for @myCardsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no cards yet. Create your first business card.'**
  String get myCardsEmpty;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cards you receive will appear here.'**
  String get inboxEmpty;

  /// No description provided for @sendSection.
  ///
  /// In en, this message translates to:
  /// **'Share my card'**
  String get sendSection;

  /// No description provided for @receiveSection.
  ///
  /// In en, this message translates to:
  /// **'Receive a card'**
  String get receiveSection;

  /// No description provided for @sendByNfc.
  ///
  /// In en, this message translates to:
  /// **'Tap phones (NFC)'**
  String get sendByNfc;

  /// No description provided for @sendByNfcHint.
  ///
  /// In en, this message translates to:
  /// **'Hold the other phone against the back of yours'**
  String get sendByNfcHint;

  /// No description provided for @showQr.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get showQr;

  /// No description provided for @receiveByNfc.
  ///
  /// In en, this message translates to:
  /// **'Read by NFC'**
  String get receiveByNfc;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQr;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get signInWithEmail;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @cardName.
  ///
  /// In en, this message translates to:
  /// **'Card name'**
  String get cardName;

  /// No description provided for @cardNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Work, Personal'**
  String get cardNameHint;

  /// No description provided for @defaultCardName.
  ///
  /// In en, this message translates to:
  /// **'My card'**
  String get defaultCardName;

  /// No description provided for @profileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSection;

  /// No description provided for @contactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactSection;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get jobTitle;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @phones.
  ///
  /// In en, this message translates to:
  /// **'Phone numbers'**
  String get phones;

  /// No description provided for @emails.
  ///
  /// In en, this message translates to:
  /// **'Email addresses'**
  String get emails;

  /// No description provided for @websites.
  ///
  /// In en, this message translates to:
  /// **'Websites'**
  String get websites;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @socialLinks.
  ///
  /// In en, this message translates to:
  /// **'Social links'**
  String get socialLinks;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @addPhone.
  ///
  /// In en, this message translates to:
  /// **'Add phone'**
  String get addPhone;

  /// No description provided for @addEmail.
  ///
  /// In en, this message translates to:
  /// **'Add email'**
  String get addEmail;

  /// No description provided for @addWebsite.
  ///
  /// In en, this message translates to:
  /// **'Add website'**
  String get addWebsite;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @addSocialLink.
  ///
  /// In en, this message translates to:
  /// **'Add social link'**
  String get addSocialLink;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'State / region'**
  String get region;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get postalCode;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @handleOrUrl.
  ///
  /// In en, this message translates to:
  /// **'Username or link'**
  String get handleOrUrl;

  /// No description provided for @labelWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get labelWork;

  /// No description provided for @labelMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get labelMobile;

  /// No description provided for @labelHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get labelHome;

  /// No description provided for @labelFax.
  ///
  /// In en, this message translates to:
  /// **'Fax'**
  String get labelFax;

  /// No description provided for @labelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get labelOther;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @logo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Crop image'**
  String get cropImage;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeImage;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this card?'**
  String get deleteCardTitle;

  /// No description provided for @deleteCardMessage.
  ///
  /// In en, this message translates to:
  /// **'This card will be removed from this device.'**
  String get deleteCardMessage;

  /// No description provided for @cardSaved.
  ///
  /// In en, this message translates to:
  /// **'Card saved'**
  String get cardSaved;

  /// No description provided for @cardNotFound.
  ///
  /// In en, this message translates to:
  /// **'This card no longer exists.'**
  String get cardNotFound;

  /// No description provided for @errorFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a full name'**
  String get errorFullNameRequired;

  /// No description provided for @errorPhoneOrEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one phone number or email address'**
  String get errorPhoneOrEmailRequired;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get errorInvalidEmail;

  /// No description provided for @errorImage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the image. Please try again.'**
  String get errorImage;

  /// No description provided for @socialOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get socialOther;

  /// No description provided for @showQrTitle.
  ///
  /// In en, this message translates to:
  /// **'My QR code'**
  String get showQrTitle;

  /// No description provided for @showQrHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the other person to scan this with eBuCard or their phone\'s camera.'**
  String get showQrHint;

  /// No description provided for @showQrNoCards.
  ///
  /// In en, this message translates to:
  /// **'Create a card first, then you can share it here.'**
  String get showQrNoCards;

  /// No description provided for @createCard.
  ///
  /// In en, this message translates to:
  /// **'Create card'**
  String get createCard;

  /// No description provided for @qrTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This card has too much information for one QR code. Remove some fields and try again.'**
  String get qrTooLarge;

  /// No description provided for @showingCard.
  ///
  /// In en, this message translates to:
  /// **'Card to share'**
  String get showingCard;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default card'**
  String get setAsDefault;

  /// No description provided for @isDefaultCard.
  ///
  /// In en, this message translates to:
  /// **'Default card'**
  String get isDefaultCard;

  /// No description provided for @defaultCardSet.
  ///
  /// In en, this message translates to:
  /// **'Default card updated'**
  String get defaultCardSet;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at an eBuCard or contact QR code.'**
  String get scanHint;

  /// No description provided for @notACard.
  ///
  /// In en, this message translates to:
  /// **'This QR code isn\'t a business card.'**
  String get notACard;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Can\'t use the camera. Allow eBuCard to use the camera in Settings.'**
  String get cameraError;

  /// No description provided for @duplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Already in your Inbox'**
  String get duplicateTitle;

  /// No description provided for @duplicateMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is already in your Inbox. Update the saved card, or keep both?'**
  String duplicateMessage(String name);

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @keepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get keepBoth;

  /// No description provided for @cardReceived.
  ///
  /// In en, this message translates to:
  /// **'Card added to your Inbox'**
  String get cardReceived;

  /// No description provided for @cardUpdated.
  ///
  /// In en, this message translates to:
  /// **'Card updated'**
  String get cardUpdated;

  /// No description provided for @searchInbox.
  ///
  /// In en, this message translates to:
  /// **'Search name, company or email'**
  String get searchInbox;

  /// No description provided for @inboxNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching cards'**
  String get inboxNoMatches;

  /// No description provided for @receivedOn.
  ///
  /// In en, this message translates to:
  /// **'Received {date}'**
  String receivedOn(String date);

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Private note'**
  String get note;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this, e.g. where you met'**
  String get noteHint;

  /// No description provided for @saveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get saveNote;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @saveToContacts.
  ///
  /// In en, this message translates to:
  /// **'Save to Contacts'**
  String get saveToContacts;

  /// No description provided for @contactsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Contacts.'**
  String get contactsError;

  /// No description provided for @cantOpenLink.
  ///
  /// In en, this message translates to:
  /// **'No app on this phone can open this.'**
  String get cantOpenLink;

  /// No description provided for @deleteReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this card from your Inbox?'**
  String get deleteReceivedTitle;

  /// No description provided for @deleteReceivedMessage.
  ///
  /// In en, this message translates to:
  /// **'It is only removed from eBuCard, not from your phone\'s Contacts.'**
  String get deleteReceivedMessage;

  /// No description provided for @nfcShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Tap phones (NFC)'**
  String get nfcShareTitle;

  /// No description provided for @nfcShareReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to share'**
  String get nfcShareReady;

  /// No description provided for @nfcShareHint.
  ///
  /// In en, this message translates to:
  /// **'Keep this screen open and hold the back of your phone against the other phone. On their phone: eBuCard → Exchange → Read by NFC.'**
  String get nfcShareHint;

  /// No description provided for @nfcCannotShare.
  ///
  /// In en, this message translates to:
  /// **'This phone can\'t share by NFC. Show your QR code instead.'**
  String get nfcCannotShare;

  /// No description provided for @nfcUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This phone doesn\'t have NFC. Use a QR code instead.'**
  String get nfcUnsupported;

  /// No description provided for @nfcOff.
  ///
  /// In en, this message translates to:
  /// **'NFC is off'**
  String get nfcOff;

  /// No description provided for @nfcOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Turn on NFC to exchange cards by tapping phones. You can use a QR code meanwhile.'**
  String get nfcOffMessage;

  /// No description provided for @openNfcSettings.
  ///
  /// In en, this message translates to:
  /// **'Open NFC settings'**
  String get openNfcSettings;

  /// No description provided for @useQrInstead.
  ///
  /// In en, this message translates to:
  /// **'Use QR code instead'**
  String get useQrInstead;

  /// No description provided for @nfcReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Read by NFC'**
  String get nfcReceiveTitle;

  /// No description provided for @nfcReceiveListening.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone against the back of the other phone'**
  String get nfcReceiveListening;

  /// No description provided for @nfcReceiveHint.
  ///
  /// In en, this message translates to:
  /// **'On their phone: eBuCard → Exchange → Tap phones (NFC). iPhones can\'t share by NFC: ask them to show their QR code.'**
  String get nfcReceiveHint;

  /// No description provided for @nfcIosAlert.
  ///
  /// In en, this message translates to:
  /// **'Hold your iPhone near the other phone.'**
  String get nfcIosAlert;

  /// No description provided for @nfcIosSuccess.
  ///
  /// In en, this message translates to:
  /// **'Card received'**
  String get nfcIosSuccess;

  /// No description provided for @nfcStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped listening.'**
  String get nfcStopped;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @nfcNotACard.
  ///
  /// In en, this message translates to:
  /// **'The other phone didn\'t share a business card.'**
  String get nfcNotACard;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signInIntro.
  ///
  /// In en, this message translates to:
  /// **'Signing in is optional. It backs up your cards and Inbox and keeps them the same on all your phones.'**
  String get signInIntro;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordHint;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a link to choose a new password.'**
  String get resetPasswordMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If an account uses that email, a reset link is on its way.'**
  String get resetEmailSent;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orContinueWith;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Your cards and Inbox will be removed from this phone. They stay safe in your account.'**
  String get signOutMessage;

  /// No description provided for @signOutUnsynced.
  ///
  /// In en, this message translates to:
  /// **'Some changes haven\'t reached your account yet (no connection). If you sign out now, they are lost.'**
  String get signOutUnsynced;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be signed out everywhere. Your account, cards, Inbox and photos are erased after 30 days. Signing in again before then cancels the deletion.'**
  String get deleteAccountMessage;

  /// No description provided for @emailConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Email confirmed'**
  String get emailConfirmed;

  /// No description provided for @emailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email to turn on sync. We sent you a link.'**
  String get emailNotConfirmed;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send the email again'**
  String get resendEmail;

  /// No description provided for @emailResent.
  ///
  /// In en, this message translates to:
  /// **'Email sent'**
  String get emailResent;

  /// No description provided for @iConfirmed.
  ///
  /// In en, this message translates to:
  /// **'I\'ve confirmed it'**
  String get iConfirmed;

  /// No description provided for @signedInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Apple'**
  String get signedInWithApple;

  /// No description provided for @signedInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get signedInWithGoogle;

  /// No description provided for @syncSection.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncSection;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @syncedAt.
  ///
  /// In en, this message translates to:
  /// **'Synced {time}'**
  String syncedAt(String time);

  /// No description provided for @notSyncedYet.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get notSyncedYet;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'You were signed out. Sign in again to keep syncing.'**
  String get sessionExpired;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach eBuCard. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Sign in instead.'**
  String get errorEmailTaken;

  /// No description provided for @errorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get errorPasswordTooShort;

  /// No description provided for @errorPasswordBreached.
  ///
  /// In en, this message translates to:
  /// **'This password has appeared in a data breach. Please choose another one.'**
  String get errorPasswordBreached;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes.'**
  String get errorTooManyRequests;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @showQrLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Anyone can scan this with their phone camera to open your card, even without eBuCard.'**
  String get showQrLinkHint;

  /// No description provided for @offlineQr.
  ///
  /// In en, this message translates to:
  /// **'Offline QR'**
  String get offlineQr;

  /// No description provided for @offlineQrHint.
  ///
  /// In en, this message translates to:
  /// **'Puts the whole card in the code, so it works without internet. Photo and logo aren\'t included.'**
  String get offlineQrHint;

  /// No description provided for @linkTitle.
  ///
  /// In en, this message translates to:
  /// **'Card link'**
  String get linkTitle;

  /// No description provided for @linkSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to get a link to this card that anyone can open, even without the app.'**
  String get linkSignInHint;

  /// No description provided for @linkConfirmEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email to turn on sync and card links.'**
  String get linkConfirmEmailHint;

  /// No description provided for @linkNone.
  ///
  /// In en, this message translates to:
  /// **'This card has no link right now.'**
  String get linkNone;

  /// No description provided for @linkMake.
  ///
  /// In en, this message translates to:
  /// **'Make a link'**
  String get linkMake;

  /// No description provided for @linkHint.
  ///
  /// In en, this message translates to:
  /// **'Share this link anywhere. It always shows your latest card.'**
  String get linkHint;

  /// No description provided for @linkCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get linkCopy;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @linkNew.
  ///
  /// In en, this message translates to:
  /// **'New link'**
  String get linkNew;

  /// No description provided for @linkNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Make a new link?'**
  String get linkNewTitle;

  /// No description provided for @linkNewMessage.
  ///
  /// In en, this message translates to:
  /// **'The current link stops working. People who already saved your card keep it.'**
  String get linkNewMessage;

  /// No description provided for @linkOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get linkOff;

  /// No description provided for @linkOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off this link?'**
  String get linkOffTitle;

  /// No description provided for @linkOffMessage.
  ///
  /// In en, this message translates to:
  /// **'The link stops working at once. QR codes and NFC will share the full card instead. You can make a new link later.'**
  String get linkOffMessage;

  /// No description provided for @linkSyncFirst.
  ///
  /// In en, this message translates to:
  /// **'This card hasn\'t synced yet. Try again in a moment.'**
  String get linkSyncFirst;

  /// No description provided for @linkInactive.
  ///
  /// In en, this message translates to:
  /// **'This card link is no longer active. Ask for the card again.'**
  String get linkInactive;

  /// No description provided for @linkOffline.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the card link. Check your connection and try again.'**
  String get linkOffline;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @cardUpToDate.
  ///
  /// In en, this message translates to:
  /// **'This card is up to date'**
  String get cardUpToDate;

  /// No description provided for @openingCard.
  ///
  /// In en, this message translates to:
  /// **'Opening card…'**
  String get openingCard;

  /// No description provided for @showQrOfflineLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Anyone can scan this with their phone camera to see your card and save it, even without eBuCard. eBuCard users don\'t need internet.'**
  String get showQrOfflineLinkHint;

  /// No description provided for @fullVcardQr.
  ///
  /// In en, this message translates to:
  /// **'Full vCard in the code'**
  String get fullVcardQr;

  /// No description provided for @fullVcardQrHint.
  ///
  /// In en, this message translates to:
  /// **'The camera opens the phone\'s new-contact screen directly instead of a web card.'**
  String get fullVcardQrHint;

  /// No description provided for @offlineLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Send this link in any chat or email. Your card is inside the link itself, so later edits don\'t change links you\'ve already shared.'**
  String get offlineLinkHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
