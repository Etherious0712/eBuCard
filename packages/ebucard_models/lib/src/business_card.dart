/// Label attached to a phone number, email or address.
enum ContactLabel { work, mobile, home, fax, other }

/// Social / messaging networks a card can link to.
enum SocialNetwork {
  linkedin,
  wechat,
  whatsapp,
  x,
  facebook,
  instagram,
  line,
  telegram,
  other,
}

class LabeledValue {
  const LabeledValue({required this.label, required this.value});

  final ContactLabel label;
  final String value;

  Map<String, Object?> toJson() => {'label': label.name, 'value': value};

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

class PostalAddress {
  const PostalAddress({
    this.label = ContactLabel.work,
    this.street = '',
    this.city = '',
    this.region = '',
    this.postalCode = '',
    this.country = '',
  });

  final ContactLabel label;
  final String street;
  final String city;
  final String region;
  final String postalCode;
  final String country;

  Map<String, Object?> toJson() => {
    'label': label.name,
    'street': street,
    'city': city,
    'region': region,
    'postalCode': postalCode,
    'country': country,
  };

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

class SocialLink {
  const SocialLink({required this.network, required this.handleOrUrl});

  final SocialNetwork network;

  /// A full URL (e.g. LinkedIn profile) or a handle/ID (e.g. WeChat ID).
  final String handleOrUrl;

  Map<String, Object?> toJson() => {
    'network': network.name,
    'handleOrUrl': handleOrUrl,
  };

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
class BusinessCard {
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

  final String id;
  final String cardName;
  final String fullName;
  final String jobTitle;
  final String company;
  final List<LabeledValue> phones;
  final List<LabeledValue> emails;
  final List<String> websites;
  final List<PostalAddress> addresses;
  final List<SocialLink> socialLinks;
  final String? photoUrl;
  final String? logoUrl;

  /// Public, revocable identifier used in the share URL. Null until the card
  /// has been synced to the server.
  final String? shareSlug;
  final DateTime updatedAt;

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

  factory BusinessCard.fromJson(Map<String, Object?> json) {
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
