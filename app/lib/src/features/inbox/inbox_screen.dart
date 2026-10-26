// Feature: inbox of received cards. Placeholder until PR B.

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../placeholder_body.dart';

/// Cards received from other people; stored locally and synced to the account.
class InboxScreen extends StatelessWidget {
  /// Creates the screen.
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navInbox)),
      body: PlaceholderBody(
        icon: Icons.inbox_outlined,
        message: l10n.inboxEmpty,
      ),
    );
  }
}
