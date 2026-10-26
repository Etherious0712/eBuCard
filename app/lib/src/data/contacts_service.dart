// "Save to Contacts": opens the phone's own new-contact screen, filled in
// from a card. The user reviews and saves it there, so the app never needs
// permission to read or write the address book.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

/// Hands a card to the phone's Contacts app.
abstract class ContactsService {
  /// Opens the system "new contact" screen pre-filled with [card].
  Future<void> addToContacts(BusinessCard card);
}

/// The real [ContactsService], using flutter_contacts' native creator screen
/// (no Contacts permission needed on Android or iOS).
class DeviceContactsService implements ContactsService {
  @override
  Future<void> addToContacts(BusinessCard card) =>
      fc.FlutterContacts.native.showCreator(contact: toContact(card));

  /// Converts [card] to the flutter_contacts model. Public for tests.
  static fc.Contact toContact(BusinessCard card) => fc.Contact(
    displayName: card.fullName,
    name: _name(card.fullName),
    phones: [
      for (final p in card.phones)
        fc.Phone(number: p.value, label: fc.Label(_phoneLabel(p.label))),
    ],
    emails: [
      for (final e in card.emails)
        fc.Email(address: e.value, label: fc.Label(_emailLabel(e.label))),
    ],
    addresses: [
      for (final a in card.addresses)
        fc.Address(
          street: a.street,
          city: a.city,
          state: a.region,
          postalCode: a.postalCode,
          country: a.country,
          label: fc.Label(_addressLabel(a.label)),
        ),
    ],
    organizations: [
      if (card.company.isNotEmpty || card.jobTitle.isNotEmpty)
        fc.Organization(name: card.company, jobTitle: card.jobTitle),
    ],
    websites: [for (final w in card.websites) fc.Website(url: w)],
    socialMedias: [
      for (final s in card.socialLinks)
        fc.SocialMedia(username: s.handleOrUrl, label: _socialLabel(s.network)),
    ],
  );

  /// Splits "Given Family" so Contacts sorts the person correctly. A name
  /// without spaces (e.g. Chinese) goes in the given name as is.
  static fc.Name _name(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return fc.Name(first: fullName.trim());
    return fc.Name(
      first: parts.sublist(0, parts.length - 1).join(' '),
      last: parts.last,
    );
  }

  /// eBuCard phone label → Contacts phone label.
  static fc.PhoneLabel _phoneLabel(ContactLabel label) => switch (label) {
    ContactLabel.work => fc.PhoneLabel.work,
    ContactLabel.mobile => fc.PhoneLabel.mobile,
    ContactLabel.home => fc.PhoneLabel.home,
    ContactLabel.fax => fc.PhoneLabel.workFax,
    ContactLabel.other => fc.PhoneLabel.other,
  };

  /// eBuCard email label → Contacts email label.
  static fc.EmailLabel _emailLabel(ContactLabel label) => switch (label) {
    ContactLabel.work => fc.EmailLabel.work,
    ContactLabel.home => fc.EmailLabel.home,
    ContactLabel.mobile => fc.EmailLabel.mobile,
    _ => fc.EmailLabel.other,
  };

  /// eBuCard address label → Contacts address label.
  static fc.AddressLabel _addressLabel(ContactLabel label) => switch (label) {
    ContactLabel.work => fc.AddressLabel.work,
    ContactLabel.home => fc.AddressLabel.home,
    _ => fc.AddressLabel.other,
  };

  /// Networks Contacts knows get their own label; others are stored as
  /// "other" with the network name as a custom label (e.g. "WeChat").
  static fc.Label<fc.SocialMediaLabel> _socialLabel(SocialNetwork network) =>
      switch (network) {
        SocialNetwork.linkedin => const fc.Label(fc.SocialMediaLabel.linkedIn),
        SocialNetwork.x => const fc.Label(fc.SocialMediaLabel.twitter),
        SocialNetwork.facebook => const fc.Label(fc.SocialMediaLabel.facebook),
        _ => fc.Label(fc.SocialMediaLabel.other, network.name),
      };
}
