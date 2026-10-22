import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../placeholder_body.dart';

/// Create (`cardId == 'new'`) or edit a card: core contact fields, photo,
/// company logo and social links.
class CardEditorScreen extends StatelessWidget {
  const CardEditorScreen({super.key, required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(cardId == 'new' ? l10n.newCard : l10n.editCard),
      ),
      body: PlaceholderBody(icon: Icons.edit_note, message: l10n.editCard),
    );
  }
}
