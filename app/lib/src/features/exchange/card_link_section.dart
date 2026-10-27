// Feature: my card's public link (DESIGN.md §4.1), under the QR code. The
// server makes a link when the card first syncs; here the owner can copy
// it, replace it (the old one stops working) or turn it off.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../account/account_providers.dart';
import '../../account/api_client.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../sync/card_links.dart';
import '../auth/api_error_text.dart';

/// The link of [card] and what the owner can do with it.
class CardLinkSection extends ConsumerStatefulWidget {
  /// Shows the link section for [card].
  const CardLinkSection({super.key, required this.card});

  /// The user's card.
  final BusinessCard card;

  @override
  ConsumerState<CardLinkSection> createState() => _CardLinkSectionState();
}

/// Tracks a link change in progress, so buttons can't be pressed twice.
class _CardLinkSectionState extends ConsumerState<CardLinkSection> {
  bool _busy = false;

  /// Asks [question] (unless null), then runs [change] and reports errors.
  Future<void> _change(
    Future<void> Function() change, {
    ({String title, String message, String confirm})? question,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (question != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(question.title),
          content: Text(question.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(question.confirm),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await change();
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            // The server doesn't have the card until it has synced.
            e.code == 'not_found' ? l10n.linkSyncFirst : apiErrorText(l10n, e),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final account = ref.watch(authProvider).value;
    final links = ref.read(cardLinksProvider);
    final url = ref.watch(sharePayloadProvider).cardUrl(widget.card);

    final Widget body;
    if (account == null || !account.canSync) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            account == null ? l10n.linkSignInHint : l10n.linkConfirmEmailHint,
          ),
          if (account == null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => context.push('/account'),
                child: Text(l10n.signIn),
              ),
            ),
        ],
      );
    } else if (url == null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.linkNone),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _busy
                  ? null
                  : () => _change(() => links.regenerate(widget.card.id)),
              icon: const Icon(Icons.add_link),
              label: Text(l10n.linkMake),
            ),
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            url.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(l10n.linkHint, style: theme.textTheme.bodySmall),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url.toString()));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
                },
                icon: const Icon(Icons.copy),
                label: Text(l10n.linkCopy),
              ),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => _change(
                        () => links.regenerate(widget.card.id),
                        question: (
                          title: l10n.linkNewTitle,
                          message: l10n.linkNewMessage,
                          confirm: l10n.linkNew,
                        ),
                      ),
                icon: const Icon(Icons.autorenew),
                label: Text(l10n.linkNew),
              ),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => _change(
                        () => links.revoke(widget.card.id),
                        question: (
                          title: l10n.linkOffTitle,
                          message: l10n.linkOffMessage,
                          confirm: l10n.linkOff,
                        ),
                      ),
                icon: const Icon(Icons.link_off),
                label: Text(l10n.linkOff),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Text(l10n.linkTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        body,
      ],
    );
  }
}
