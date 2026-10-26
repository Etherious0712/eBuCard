// Translated display names for model enums, used by the editor dropdowns.

import 'package:ebucard_models/ebucard_models.dart';

import '../../l10n/generated/app_localizations.dart';

/// Display names for [ContactLabel] values.
extension ContactLabelText on ContactLabel {
  /// The label in the current UI language, e.g. "Mobile" or "手機".
  String text(AppLocalizations l10n) => switch (this) {
    ContactLabel.work => l10n.labelWork,
    ContactLabel.mobile => l10n.labelMobile,
    ContactLabel.home => l10n.labelHome,
    ContactLabel.fax => l10n.labelFax,
    ContactLabel.other => l10n.labelOther,
  };
}

/// Display names for [SocialNetwork] values.
extension SocialNetworkText on SocialNetwork {
  /// Brand names are not translated; only "Other" is.
  String text(AppLocalizations l10n) => switch (this) {
    SocialNetwork.linkedin => 'LinkedIn',
    SocialNetwork.wechat => 'WeChat',
    SocialNetwork.whatsapp => 'WhatsApp',
    SocialNetwork.x => 'X',
    SocialNetwork.facebook => 'Facebook',
    SocialNetwork.instagram => 'Instagram',
    SocialNetwork.line => 'LINE',
    SocialNetwork.telegram => 'Telegram',
    SocialNetwork.other => l10n.socialOther,
  };
}
