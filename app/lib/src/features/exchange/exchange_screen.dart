// Feature: exchange. Lists the send/receive options this phone supports:
// QR on every phone, NFC where the hardware allows (see
// exchange_capabilities.dart). NFC options say so when NFC is switched off.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/exchange_capabilities.dart';
import '../../data/nfc_service.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// Send or receive a card. Shows only the methods this phone supports.
class ExchangeScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const ExchangeScreen({super.key});

  @override
  ConsumerState<ExchangeScreen> createState() => _ExchangeScreenState();
}

/// Re-checks NFC when the app comes back (the user may have changed it).
class _ExchangeScreenState extends ConsumerState<ExchangeScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(nfcStatusProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(nfcStatusProvider).value ?? NfcStatus.unsupported;
    final caps = ExchangeCapabilities.resolve(
      platform: Theme.of(context).platform,
      nfcAvailable: status.state != NfcState.unsupported,
      hceSupported: status.canShare,
    );
    // Shown under the NFC options while NFC is switched off.
    final nfcOff = status.state == NfcState.off ? Text(l10n.nfcOff) : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navExchange)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.sendSection, style: Theme.of(context).textTheme.titleSmall),
          ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: Text(l10n.showQr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/exchange/show-qr'),
          ),
          if (caps.send.contains(SendMethod.nfcHce))
            ListTile(
              leading: const Icon(Icons.nfc),
              title: Text(l10n.sendByNfc),
              subtitle: nfcOff,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/exchange/nfc-share'),
            ),
          const Divider(),
          Text(
            l10n.receiveSection,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: Text(l10n.scanQr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/exchange/scan'),
          ),
          if (caps.receive.contains(ReceiveMethod.nfcRead))
            ListTile(
              leading: const Icon(Icons.contactless_outlined),
              title: Text(l10n.receiveByNfc),
              subtitle: nfcOff,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/exchange/nfc-receive'),
            ),
        ],
      ),
    );
  }
}
