// Translations are kept one per line for easy review.
// ignore_for_file: lines_longer_than_80_chars

// Text the server itself shows people: emails and the small web pages for
// email verification and password reset. Same three languages as the app.

/// Languages the server writes in.
enum ServerLocale {
  /// English.
  en,

  /// Traditional Chinese.
  zhHant,

  /// Simplified Chinese.
  zhHans,
}

/// Picks a [ServerLocale] from an `Accept-Language` header (or the app's
/// locale tag), using the same rules as the app: Chinese with Hant or a
/// TW/HK/MO region is Traditional, other Chinese is Simplified, everything
/// else is English.
ServerLocale localeFromHeader(String? header) {
  if (header == null) return ServerLocale.en;
  for (final part in header.split(',')) {
    final tag = part.split(';').first.trim().toLowerCase().replaceAll('_', '-');
    if (tag.isEmpty || tag == '*') continue;
    final subtags = tag.split('-');
    if (subtags.first != 'zh') {
      if (subtags.first == 'en') return ServerLocale.en;
      continue;
    }
    if (subtags.contains('hant') ||
        subtags.any((s) => const {'tw', 'hk', 'mo'}.contains(s))) {
      return ServerLocale.zhHant;
    }
    return ServerLocale.zhHans;
  }
  return ServerLocale.en;
}

/// All server-side text in one language.
class ServerStrings {
  const ServerStrings._(this._t);

  /// Strings for [locale].
  factory ServerStrings.of(ServerLocale locale) => switch (locale) {
    ServerLocale.en => const ServerStrings._(_en),
    ServerLocale.zhHant => const ServerStrings._(_zhHant),
    ServerLocale.zhHans => const ServerStrings._(_zhHans),
  };

  final Map<String, String> _t;

  /// HTML `lang` attribute value.
  String get htmlLang => _t['lang']!;

  /// Subject of the verification email.
  String get verifySubject => _t['verifySubject']!;

  /// Body of the verification email with the [link] to open.
  String verifyBody(String link) =>
      _t['verifyBody']!.replaceAll('{link}', link);

  /// Subject of the password-reset email.
  String get resetSubject => _t['resetSubject']!;

  /// Body of the password-reset email with the [link] to open.
  String resetBody(String link) => _t['resetBody']!.replaceAll('{link}', link);

  /// Page title after a successful verification.
  String get verifiedTitle => _t['verifiedTitle']!;

  /// Page text after a successful verification.
  String get verifiedBody => _t['verifiedBody']!;

  /// Page title for an expired or already-used link.
  String get linkInvalidTitle => _t['linkInvalidTitle']!;

  /// Page text for an expired or already-used link.
  String get linkInvalidBody => _t['linkInvalidBody']!;

  /// Title of the "choose a new password" page.
  String get resetTitle => _t['resetTitle']!;

  /// Label of the new-password field.
  String get newPassword => _t['newPassword']!;

  /// Label of the repeat-password field.
  String get repeatPassword => _t['repeatPassword']!;

  /// Submit button on the reset page.
  String get resetButton => _t['resetButton']!;

  /// Error: the two passwords differ.
  String get passwordsDiffer => _t['passwordsDiffer']!;

  /// Error: the password is shorter than 8 characters.
  String get passwordTooShort => _t['passwordTooShort']!;

  /// Error: the password appears in known data breaches.
  String get passwordBreached => _t['passwordBreached']!;

  /// Page title after the password was changed.
  String get resetDoneTitle => _t['resetDoneTitle']!;

  /// Page text after the password was changed.
  String get resetDoneBody => _t['resetDoneBody']!;
}

const _en = {
  'lang': 'en',
  'verifySubject': 'Confirm your email for eBuCard',
  'verifyBody':
      "Welcome to eBuCard!\n\nOpen this link to confirm your email address and turn on sync:\n{link}\n\nThe link works for 24 hours. If you didn't create an eBuCard account, you can ignore this email.",
  'resetSubject': 'Reset your eBuCard password',
  'resetBody':
      "Someone asked to reset the password for this eBuCard account.\n\nOpen this link to choose a new password:\n{link}\n\nThe link works for 1 hour. If it wasn't you, ignore this email; your password stays the same.",
  'verifiedTitle': 'Email confirmed',
  'verifiedBody': 'Thanks! Sync is now on. You can go back to the eBuCard app.',
  'linkInvalidTitle': 'This link no longer works',
  'linkInvalidBody':
      'It has expired or was already used. Request a new one in the eBuCard app.',
  'resetTitle': 'Choose a new password',
  'newPassword': 'New password (at least 8 characters)',
  'repeatPassword': 'Repeat the new password',
  'resetButton': 'Change password',
  'passwordsDiffer': 'The two passwords are different.',
  'passwordTooShort': 'Use at least 8 characters.',
  'passwordBreached':
      'This password has appeared in a data breach. Please choose another one.',
  'resetDoneTitle': 'Password changed',
  'resetDoneBody':
      'Sign in to eBuCard with your new password. Other phones have been signed out.',
};

const _zhHant = {
  'lang': 'zh-Hant',
  'verifySubject': '確認你的 eBuCard 電郵地址',
  'verifyBody':
      '歡迎使用 eBuCard！\n\n請開啟以下連結確認你的電郵地址並啟用同步：\n{link}\n\n連結有效期為 24 小時。如果你沒有建立 eBuCard 帳戶，請忽略此電郵。',
  'resetSubject': '重設你的 eBuCard 密碼',
  'resetBody':
      '有人要求重設此 eBuCard 帳戶的密碼。\n\n請開啟以下連結設定新密碼：\n{link}\n\n連結有效期為 1 小時。如果不是你本人，請忽略此電郵，你的密碼不會改變。',
  'verifiedTitle': '電郵地址已確認',
  'verifiedBody': '謝謝！同步已啟用，你可以返回 eBuCard 應用程式。',
  'linkInvalidTitle': '此連結已失效',
  'linkInvalidBody': '連結已過期或已被使用。請在 eBuCard 應用程式中重新申請。',
  'resetTitle': '設定新密碼',
  'newPassword': '新密碼（至少 8 個字元）',
  'repeatPassword': '再次輸入新密碼',
  'resetButton': '更改密碼',
  'passwordsDiffer': '兩次輸入的密碼不一致。',
  'passwordTooShort': '請使用至少 8 個字元。',
  'passwordBreached': '此密碼曾在資料外洩事件中出現，請選擇其他密碼。',
  'resetDoneTitle': '密碼已更改',
  'resetDoneBody': '請使用新密碼登入 eBuCard。其他手機已被登出。',
};

const _zhHans = {
  'lang': 'zh-Hans',
  'verifySubject': '确认你的 eBuCard 邮箱地址',
  'verifyBody':
      '欢迎使用 eBuCard！\n\n请打开以下链接确认你的邮箱地址并启用同步：\n{link}\n\n链接有效期为 24 小时。如果你没有创建 eBuCard 账户，请忽略此邮件。',
  'resetSubject': '重置你的 eBuCard 密码',
  'resetBody':
      '有人请求重置此 eBuCard 账户的密码。\n\n请打开以下链接设置新密码：\n{link}\n\n链接有效期为 1 小时。如果不是你本人，请忽略此邮件，你的密码不会改变。',
  'verifiedTitle': '邮箱地址已确认',
  'verifiedBody': '谢谢！同步已启用，你可以返回 eBuCard 应用。',
  'linkInvalidTitle': '此链接已失效',
  'linkInvalidBody': '链接已过期或已被使用。请在 eBuCard 应用中重新申请。',
  'resetTitle': '设置新密码',
  'newPassword': '新密码（至少 8 个字符）',
  'repeatPassword': '再次输入新密码',
  'resetButton': '更改密码',
  'passwordsDiffer': '两次输入的密码不一致。',
  'passwordTooShort': '请使用至少 8 个字符。',
  'passwordBreached': '此密码曾在数据泄露事件中出现，请选择其他密码。',
  'resetDoneTitle': '密码已更改',
  'resetDoneBody': '请使用新密码登录 eBuCard。其他手机已退出登录。',
};
