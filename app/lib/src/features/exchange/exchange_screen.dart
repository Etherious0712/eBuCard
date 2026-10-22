import 'package:flutter/material.dart';

import '../../core/exchange_capabilities.dart';
import '../../l10n/generated/app_localizations.dart';

/// Send or receive a card. Shows only the methods this platform supports.
class ExchangeScreen extends StatelessWidget {
  const ExchangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // NFC hardware/HCE detection arrives with the NFC plugin; until then the
    // UI assumes the hardware is present so both layouts can be reviewed.
    final caps = ExchangeCapabilities.resolve(
      platform: Theme.of(context).platform,
      nfcAvailable: true,
      hceSupported: true,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navExchange)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.sendSection, style: Theme.of(context).textTheme.titleSmall),
          if (caps.send.contains(SendMethod.nfcHce))
            ListTile(
              leading: const Icon(Icons.nfc),
              title: Text(l10n.sendByNfc),
              subtitle: Text(l10n.sendByNfcHint),
              enabled: false,
            ),
          ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: Text(l10n.showQr),
            enabled: false,
          ),
          const Divider(),
          Text(
            l10n.receiveSection,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (caps.receive.contains(ReceiveMethod.nfcRead))
            ListTile(
              leading: const Icon(Icons.contactless_outlined),
              title: Text(l10n.receiveByNfc),
              enabled: false,
            ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: Text(l10n.scanQr),
            enabled: false,
          ),
          const SizedBox(height: 16),
          Text(l10n.comingSoon, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
