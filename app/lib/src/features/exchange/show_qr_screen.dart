// Feature: show my QR code. Shares the card chosen in share_card.dart (the
// default card unless the user switched; the NFC screen shares the same
// one).
//
// * Default (no server): the QR code holds an offline card link, the card
//   inside the link. A phone camera opens the web card; eBuCard reads it
//   without internet. "Full vCard" switches to a plain vCard, which a
//   camera turns straight into a new contact (DESIGN.md §4.3).
// * Cloud features on: once the card has synced, the QR code holds its
//   server link (short, always the latest card); "Offline QR" switches to
//   the full vCard.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:flutter/services.dart';

import '../../core/config.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../sync/card_links.dart';
import 'card_link_section.dart';
import 'share_card.dart';

/// Shows one of the user's cards as a QR code.
class ShowQrScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const ShowQrScreen({super.key});

  @override
  ConsumerState<ShowQrScreen> createState() => _ShowQrScreenState();
}

/// Holds the "vCard instead of link" choice for this visit.
class _ShowQrScreenState extends ConsumerState<ShowQrScreen> {
  bool _offline = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final payload = ref.watch(sharePayloadProvider);
    final cloud = ref.watch(cloudEnabledProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.showQrTitle)),
      body: ref
          .watch(shareCardProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (card) {
              if (card == null) {
                return const NoCardsToShare(icon: Icons.qr_code_2);
              }
              if (!cloud) return _offlineBody(context, card);
              final hasLink = payload.cardUrl(card) != null;
              final showsLink = hasLink && !_offline;
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ShareCardDropdown(selected: card),
                  const SizedBox(height: 24),
                  _CardQr(
                    card: card,
                    text: payload.qrText(card, offline: _offline),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    card.fullName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showsLink ? l10n.showQrLinkHint : l10n.showQrHint,
                    textAlign: TextAlign.center,
                  ),
                  if (hasLink)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.offlineQr),
                      subtitle: Text(l10n.offlineQrHint),
                      value: _offline,
                      onChanged: (value) => setState(() => _offline = value),
                    ),
                  CardLinkSection(card: card),
                ],
              );
            },
          ),
    );
  }

  /// The screen without a server: offline link by default, or the vCard.
  Widget _offlineBody(BuildContext context, BusinessCard card) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final link = ref.read(offlineLinksProvider).linkFor(card);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ShareCardDropdown(selected: card),
        const SizedBox(height: 24),
        _CardQr(
          card: card,
          text: _offline
              ? const VCardEncoder().encode(card, includeImages: false)
              : link.toString(),
        ),
        const SizedBox(height: 16),
        Text(
          card.fullName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _offline ? l10n.showQrHint : l10n.showQrOfflineLinkHint,
          textAlign: TextAlign.center,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.fullVcardQr),
          subtitle: Text(l10n.fullVcardQrHint),
          value: _offline,
          onChanged: (value) => setState(() => _offline = value),
        ),
        const Divider(height: 32),
        Text(l10n.linkTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(l10n.offlineLinkHint, style: theme.textTheme.bodySmall),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link.toString()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.linkCopy),
          ),
        ),
      ],
    );
  }
}

/// The QR code holding [text] for [card], or a message if it is too big.
class _CardQr extends StatelessWidget {
  const _CardQr({required this.card, required this.text});

  /// The card shown (for the screen-reader label).
  final BusinessCard card;

  /// What the code holds: the card link or the vCard.
  final String text;

  @override
  Widget build(BuildContext context) {
    // Low error correction leaves the most room for data; the code is shown
    // on a bright screen, not printed, so it rarely gets damaged.
    final validation = QrValidator.validate(
      data: text,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    if (validation.status != QrValidationStatus.valid) {
      return Text(
        AppLocalizations.of(context).qrTooLarge,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    return Center(
      child: Container(
        // Always dark-on-white with a quiet zone, even in dark mode, so
        // every scanner can read it.
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: QrImageView.withQr(
          qr: validation.qrCode!,
          size: 280,
          semanticsLabel: card.fullName,
        ),
      ),
    );
  }
}
