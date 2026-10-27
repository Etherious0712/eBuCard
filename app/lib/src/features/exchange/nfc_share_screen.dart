// Feature: share my card by NFC (Android). While this screen is open, the
// phone acts as an NFC tag holding the card (CardHostApduService.kt), so
// another phone held against it can read the card. Sharing stops as soon as
// the screen closes or the app goes to the background.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/nfc_service.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../sync/card_links.dart';
import 'nfc_unavailable.dart';
import 'share_card.dart';

/// "Tap phones (NFC)": shares the chosen card while open.
class NfcShareScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const NfcShareScreen({super.key});

  @override
  ConsumerState<NfcShareScreen> createState() => _NfcShareScreenState();
}

/// Keeps the native side's shared card in step with what the screen shows.
class _NfcShareScreenState extends ConsumerState<NfcShareScreen> {
  /// Read once: `ref` can't be used in [dispose].
  late final NfcService _nfc;

  /// Re-checks NFC (the user may have switched it on in settings) and
  /// restarts sharing when the app returns to the foreground.
  late final AppLifecycleListener _lifecycle;

  /// The card currently being served, or null when not sharing.
  BusinessCard? _sharedCard;

  @override
  void initState() {
    super.initState();
    _nfc = ref.read(nfcServiceProvider);
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _sharedCard = null; // Android stopped sharing when the app paused.
        ref.invalidate(nfcStatusProvider);
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _nfc.stopSharing();
    super.dispose();
  }

  /// Starts sharing [card], or stops when it is null. Does nothing if that
  /// card (same id, version and link) is already being shared.
  void _share(BusinessCard? card) {
    final same =
        card?.id == _sharedCard?.id &&
        card?.updatedAt == _sharedCard?.updatedAt &&
        card?.shareSlug == _sharedCard?.shareSlug;
    if (same) return;
    _sharedCard = card;
    if (card == null) {
      _nfc.stopSharing();
    } else {
      // The card link (once synced) first, so phones open the latest
      // card; the vCard after it works without internet (DESIGN.md §4.2).
      _nfc.startSharing(
        cardNdefBytes(
          card,
          cardUrl: ref.read(sharePayloadProvider).cardUrl(card),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(nfcStatusProvider);
    final card = ref.watch(shareCardProvider);

    Widget body;
    BusinessCard? toShare;
    if (status.isLoading || card.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (status.value?.state != NfcState.on ||
        status.value?.canShare != true) {
      final state = status.value?.state ?? NfcState.unsupported;
      body = NfcUnavailable(
        state: state,
        qrRoute: '/exchange/show-qr',
        message: state == NfcState.on ? l10n.nfcCannotShare : null,
      );
    } else if (card.value == null) {
      body = const NoCardsToShare(icon: Icons.nfc);
    } else {
      toShare = card.value;
      body = _ReadyToShare(card: toShare!);
    }
    // Native sharing follows what is on screen; run after this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _share(toShare);
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nfcShareTitle)),
      body: body,
    );
  }
}

/// The "ready" state: card switcher, NFC icon, card name and instructions.
class _ReadyToShare extends StatelessWidget {
  const _ReadyToShare({required this.card});

  /// The card being shared.
  final BusinessCard card;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ShareCardDropdown(selected: card),
        const SizedBox(height: 32),
        Icon(Icons.nfc, size: 120, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          l10n.nfcShareReady,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        Text(
          card.fullName,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(l10n.nfcShareHint, textAlign: TextAlign.center),
      ],
    );
  }
}
