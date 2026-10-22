import 'dart:convert';

/// Where card links point. Phase 2 replaces this with the real eBuCard
/// domain, which will serve a profile page for people without the app.
const cardLinkBase = 'https://example.com/ebucard/c';

/// A business card. For the proof of concept the whole card travels inside
/// the link (in the URL fragment, which browsers never send to a server),
/// so no backend is needed yet.
class BusinessCard {
  const BusinessCard({
    required this.name,
    this.title = '',
    this.company = '',
    this.phone = '',
    this.email = '',
    this.website = '',
  });

  final String name;
  final String title;
  final String company;
  final String phone;
  final String email;
  final String website;

  bool get isEmpty => name.trim().isEmpty;

  Map<String, String> toJson() => {
    'n': name,
    if (title.isNotEmpty) 't': title,
    if (company.isNotEmpty) 'c': company,
    if (phone.isNotEmpty) 'p': phone,
    if (email.isNotEmpty) 'e': email,
    if (website.isNotEmpty) 'w': website,
  };

  factory BusinessCard.fromJson(Map<String, dynamic> json) => BusinessCard(
    name: json['n'] as String? ?? '',
    title: json['t'] as String? ?? '',
    company: json['c'] as String? ?? '',
    phone: json['p'] as String? ?? '',
    email: json['e'] as String? ?? '',
    website: json['w'] as String? ?? '',
  );

  String toLink() {
    final payload = base64Url.encode(utf8.encode(jsonEncode(toJson())));
    return '$cardLinkBase#${payload.replaceAll('=', '')}';
  }

  /// Returns null when [link] is not an eBuCard link.
  static BusinessCard? fromLink(String link) {
    final hash = link.indexOf('#');
    if (hash < 0 || link.substring(0, hash) != cardLinkBase) return null;
    try {
      final payload = base64Url.normalize(link.substring(hash + 1));
      final json = jsonDecode(utf8.decode(base64Url.decode(payload)));
      if (json is! Map<String, dynamic>) return null;
      final card = BusinessCard.fromJson(json);
      return card.isEmpty ? null : card;
    } on FormatException {
      return null;
    }
  }
}
