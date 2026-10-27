// Feature: read a card from another phone by NFC.
//
// Android: listens as soon as the screen opens and keeps listening until a
// card is read or the screen closes.
// iPhone: opening the screen shows iOS's own "Ready to Scan" sheet; if the
// user closes it (or it times out), the screen offers "Try again".
// A card read here goes through the same Inbox flow as a QR scan
// (receive_card.dart), including the "Update or keep both" question.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ndef_record/ndef_record.dart';

import '../../data/nfc_service.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'nfc_unavailable.dart';
import 'receive_card.dart';

/// "Read by NFC": waits for another phone and saves its card to the Inbox.
class NfcReceiveScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const NfcReceiveScreen({super.key});

  @override
  ConsumerState<NfcReceiveScreen> createState() => _NfcReceiveScreenState();
}

/// Runs the reading session and handles what it reads.
class _NfcReceiveScreenState extends ConsumerState<NfcReceiveScreen> {
  /// Read once: `ref` can't be used in [dispose].
  late final NfcService _nfc;

  /// Re-checks NFC when the app returns (e.g. from the NFC settings).
  late final AppLifecycleListener _lifecycle;

  /// A reading session is running.
  bool _listening = false;

  /// A read card is being saved; further reads are ignored meanwhile.
  bool _handling = false;

  /// iPhone opens its scan sheet automatically only once; after that the
  /// user taps "Try again".
  bool _autoStarted = false;

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _nfc = ref.read(nfcServiceProvider);
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(nfcStatusProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    if (_listening) _nfc.stopReading();
    super.dispose();
  }

  /// Starts a reading session (shows the sheet on iPhone).
  Future<void> _start() async {
    if (_listening) return;
    setState(() => _listening = true);
    final l10n = AppLocalizations.of(context);
    await _nfc.startReading(
      iosAlertMessage: l10n.nfcIosAlert,
      onMessage: _onMessage,
      onCancelledIos: () {
        if (mounted) setState(() => _listening = false);
      },
    );
  }

  /// Handles one read: saves the card and opens it, or explains the problem.
  Future<void> _onMessage(NdefMessage? message) async {
    if (_handling || !mounted) return;
    _handling = true;
    final l10n = AppLocalizations.of(context);
    final text = message == null ? null : contactTextFromNdef(message);
    final link = message == null ? null : uriFromNdef(message)?.toString();

    if (_isIos) {
      // iOS closes its sheet after one read either way.
      await _nfc.stopReading(
        iosSuccessMessage: text == null && link == null
            ? null
            : l10n.nfcIosSuccess,
        iosErrorMessage: text == null && link == null ? l10n.nfcNotACard : null,
      );
      if (mounted) setState(() => _listening = false);
    }
    if (!mounted) return;

    // Online, the card link gives the latest card with photo and logo;
    // otherwise the vCard on the tag is used. With neither, the user is
    // told it isn't a business card.
    final id = await receiveCard(
      context,
      ref,
      link: link,
      contactText: text,
      via: ReceivedVia.nfc,
    );
    _handling = false;
    if (!mounted) return;
    if (id != null) {
      if (_listening) await _nfc.stopReading();
      _listening = false;
      if (mounted) context.go('/inbox/$id');
    }
    // Otherwise Android keeps listening for the next tap; iPhone shows
    // "Try again".
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = ref.watch(nfcStatusProvider);

    Widget body;
    if (status.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (status.value?.state != NfcState.on) {
      body = NfcUnavailable(
        state: status.value?.state ?? NfcState.unsupported,
        qrRoute: '/exchange/scan',
      );
    } else {
      if (!_listening && (!_isIos || !_autoStarted)) {
        // Android listens whenever this screen is showing; iPhone opens the
        // scan sheet once on arrival.
        _autoStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _start();
        });
      }
      body = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.contactless_outlined,
            size: 120,
            color: _listening
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _listening ? l10n.nfcReceiveListening : l10n.nfcStopped,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(l10n.nfcReceiveHint, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (!_listening)
            Center(
              child: FilledButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.nfc),
                label: Text(l10n.tryAgain),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nfcReceiveTitle)),
      body: body,
    );
  }
}
