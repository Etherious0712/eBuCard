// The signed-in account as the server describes it.

/// An eBuCard account.
class Account {
  /// Creates an account.
  const Account({
    required this.id,
    this.email,
    this.emailVerified = false,
    this.canSync = false,
    this.hasPassword = false,
    this.apple = false,
    this.google = false,
  });

  /// Reads `GET /v1/account` (or the `account` part of a sign-in) JSON.
  factory Account.fromJson(Map<String, Object?> json) => Account(
    id: json['id']! as String,
    email: json['email'] as String?,
    emailVerified: json['emailVerified'] == true,
    canSync: json['canSync'] == true,
    hasPassword: json['hasPassword'] == true,
    apple: json['apple'] == true,
    google: json['google'] == true,
  );

  /// Account id.
  final String id;

  /// Email address, if any (Apple may hide it).
  final String? email;

  /// Whether the email is confirmed.
  final bool emailVerified;

  /// Whether sync is allowed (confirmed email, or Apple/Google account).
  final bool canSync;

  /// Whether the account has a password.
  final bool hasPassword;

  /// Linked to Sign in with Apple.
  final bool apple;

  /// Linked to Google sign-in.
  final bool google;

  /// JSON, for storing the last known account on the phone.
  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'emailVerified': emailVerified,
    'canSync': canSync,
    'hasPassword': hasPassword,
    'apple': apple,
    'google': google,
  };
}
