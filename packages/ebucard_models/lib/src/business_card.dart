// Domain model for a business card, shared by the Flutter app and the server.
//
// Every type here is immutable and round-trips through JSON with `toJson` /
// `fromJson`. That JSON is the single format used for local storage (SQLite),
// the REST API and sync, so a change here changes all three. Add new fields
// as optional, with a default, so older stored data still decodes.

/// Label attached to a phone number, email or address, e.g. "work" or
/// "mobile". Stored by [Enum.name], so renaming a value breaks stored data.
enum ContactLabel {
  /// Work / office.
  work,

  /// Mobile phone. Only meaningful for phone numbers.
  mobile,

  /// Home / personal.
  home,

  /// Fax. Only meaningful for phone numbers.
  fax,

  /// Anything else.
  other,
}

/// Social and messaging networks a card can link to. Stored by [Enum.name],
/// so renaming a value breaks stored data; add new networks at the end.
enum SocialNetwork {
  /// LinkedIn profile URL.
  linkedin,

  /// WeChat ID.
  wechat,

  /// WhatsApp number or link.
  whatsapp,

  /// X (formerly Twitter) handle.
  x,

  /// Facebook profile.
  facebook,

  /// Instagram handle.
  instagram,

  /// LINE ID.
  line,

  /// Telegram username.
  telegram,

  /// Any other network; the value is usually a full URL.
  other,
}

/// A single labeled value, used for phone numbers and email addresses.
class LabeledValue {
  /// Creates a value with its [label], e.g. a mobile phone number.
  const LabeledValue({required this.label, required this.value});

  /// What kind of number or address this is.
  final ContactLabel label;

  /// The phone number or email address as the user typed it.
  final String value;

  /// Encodes this value as JSON: `{"label": "mobile", "value": "..."}`.
  Map<String, Object?> toJson() => {'label': label.name, 'value': value};

  /// Decodes a value written by [toJson].
  factory LabeledValue.fromJson(Map<String, Object?> json) => LabeledValue(
    label: ContactLabel.values.byName(json['label']! as String),
    value: json['value']! as String,
  );

  @override
  bool operator ==(Object other) =>
      other is LabeledValue && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);
}

/// A postal address. All parts are optional; empty strings mean "not set".
class PostalAddress {
  /// Creates an address. Every part defaults to empty.
  const PostalAddress({
    this.label = ContactLabel.work,
    this.street = '',
    this.city = '',
    this.region = '',
    this.postalCode = '',
    this.country = '',
  });

  /// Work, home, etc.
  final ContactLabel label;

  /// Street and building, possibly several lines.
  final String street;

  /// City or town.
  final String city;

  /// State, province or region.
  final String region;

  /// Postal / ZIP code.
  final String postalCode;

  /// Country or territory name.
  final String country;

  /// Encodes this address as JSON.
  Map<String, Object?> toJson() => {
    'label': label.name,
    'street': street,
    'city': city,
    'region': region,
    'postalCode': postalCode,
    'country': country,
  };

  /// Decodes an address written by [toJson]. Missing parts become empty.
  factory PostalAddress.fromJson(Map<String, Object?> json) => PostalAddress(
    label: ContactLabel.values.byName(json['label']! as String),
    street: json['street'] as String? ?? '',
    city: json['city'] as String? ?? '',
    region: json['region'] as String? ?? '',
    postalCode: json['postalCode'] as String? ?? '',
    country: json['country'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) =>
      other is PostalAddress &&
      other.label == label &&
      other.street == street &&
      other.city == city &&
      other.region == region &&
      other.postalCode == postalCode &&
      other.country == country;

  @override
  int get hashCode =>
      Object.hash(label, street, city, region, postalCode, country);
}

/// A link to the card owner's profile on a social or messaging network.
class SocialLink {
  /// Creates a link to [network].
  const SocialLink({required this.network, required this.handleOrUrl});

  /// Which network this is.
  final SocialNetwork network;

  /// A full URL (e.g. LinkedIn profile) or a handle/ID (e.g. WeChat ID).
  final String handleOrUrl;

  /// Encodes this link as JSON.
  Map<String, Object?> toJson() => {
    'network': network.name,
    'handleOrUrl': handleOrUrl,
  };

  /// Decodes a link written by [toJson].
  factory SocialLink.fromJson(Map<String, Object?> json) => SocialLink(
    network: SocialNetwork.values.byName(json['network']! as String),
    handleOrUrl: json['handleOrUrl']! as String,
  );

  @override
  bool operator ==(Object other) =>
      other is SocialLink &&
      other.network == network &&
      other.handleOrUrl == handleOrUrl;

  @override
  int get hashCode => Object.hash(network, handleOrUrl);
}

/// A single business card. One user may own several cards
/// (e.g. "Work" and "Personal"); [cardName] tells them apart.
///
/// Whether a card is complete enough to save is decided by `validateCard`
/// (see `card_validation.dart`), not by this class.
class BusinessCard {
  /// Creates a card. Only [id], [cardName], [fullName] and [updatedAt] are
  /// required here; everything else defaults to empty.
  const BusinessCard({
    required this.id,
    required this.cardName,
    required this.fullName,
    this.jobTitle = '',
    this.company = '',
    this.phones = const [],
    this.emails = const [],
    this.websites = const [],
    this.addresses = const [],
    this.socialLinks = const [],
    this.photoUrl,
    this.logoUrl,
    this.shareSlug,
    required this.updatedAt,
  });

  /// Stable unique ID (a UUID created on the device).
  final String id;

  /// The owner's own label for this card, e.g. "Work". Never shared.
  final String cardName;

  /// The person's name as it should appear on the card.
  final String fullName;

  /// Job title, e.g. "Sales Director". May be empty.
  final String jobTitle;

  /// Company or organisation name. May be empty.
  final String company;

  /// Phone numbers, in display order.
  final List<LabeledValue> phones;

  /// Email addresses, in display order.
  final List<LabeledValue> emails;

  /// Website URLs, in display order.
  final List<String> websites;

  /// Postal addresses, in display order.
  final List<PostalAddress> addresses;

  /// Social network profiles, in display order.
  final List<SocialLink> socialLinks;

  /// Profile photo. A `file:` URI while the image only exists on the device,
  /// an `https:` URL once uploaded. Only `http(s)` URLs are ever shared.
  final String? photoUrl;

  /// Company logo; same rules as [photoUrl].
  final String? logoUrl;

  /// Public, revocable identifier used in the share URL. Null until the card
  /// has been synced to the server.
  final String? shareSlug;

  /// When the card was last changed (UTC). Used for sync conflict handling.
  final DateTime updatedAt;

  /// Encodes the whole card as JSON. [updatedAt] is written as UTC ISO-8601.
  Map<String, Object?> toJson() => {
    'id': id,
    'cardName': cardName,
    'fullName': fullName,
    'jobTitle': jobTitle,
    'company': company,
    'phones': [for (final p in phones) p.toJson()],
    'emails': [for (final e in emails) e.toJson()],
    'websites': websites,
    'addresses': [for (final a in addresses) a.toJson()],
    'socialLinks': [for (final s in socialLinks) s.toJson()],
    'photoUrl': photoUrl,
    'logoUrl': logoUrl,
    'shareSlug': shareSlug,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  /// Decodes a card written by [toJson]. Missing optional fields fall back
  /// to their defaults, so older stored cards still load.
  factory BusinessCard.fromJson(Map<String, Object?> json) {
    // Reads a JSON array of objects, treating a missing key as empty.
    List<Map<String, Object?>> list(String key) =>
        ((json[key] as List?) ?? const []).cast<Map<String, Object?>>();
    return BusinessCard(
      id: json['id']! as String,
      cardName: json['cardName']! as String,
      fullName: json['fullName']! as String,
      jobTitle: json['jobTitle'] as String? ?? '',
      company: json['company'] as String? ?? '',
      phones: list('phones').map(LabeledValue.fromJson).toList(),
      emails: list('emails').map(LabeledValue.fromJson).toList(),
      websites: ((json['websites'] as List?) ?? const []).cast<String>(),
      addresses: list('addresses').map(PostalAddress.fromJson).toList(),
      socialLinks: list('socialLinks').map(SocialLink.fromJson).toList(),
      photoUrl: json['photoUrl'] as String?,
      logoUrl: json['logoUrl'] as String?,
      shareSlug: json['shareSlug'] as String?,
      updatedAt: DateTime.parse(json['updatedAt']! as String),
    );
  }
}
