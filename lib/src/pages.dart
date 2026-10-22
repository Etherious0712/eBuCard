import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'business_card.dart';
import 'nfc_receive.dart';
import 'nfc_share.dart';

class CardView extends StatelessWidget {
  const CardView({super.key, required this.card, this.onEdit});

  final BusinessCard card;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final subtitle = [
      card.title,
      card.company,
    ].where((s) => s.isNotEmpty).join(' · ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(card.name, style: text.titleLarge)),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                  ),
              ],
            ),
            if (subtitle.isNotEmpty) Text(subtitle, style: text.bodyMedium),
            const SizedBox(height: 8),
            for (final line in [card.phone, card.email, card.website])
              if (line.isNotEmpty) Text(line),
          ],
        ),
      ),
    );
  }
}

class EditCardPage extends StatefulWidget {
  const EditCardPage({super.key, this.initial});

  final BusinessCard? initial;

  @override
  State<EditCardPage> createState() => _EditCardPageState();
}

class _EditCardPageState extends State<EditCardPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _company = TextEditingController(text: widget.initial?.company);
  late final _phone = TextEditingController(text: widget.initial?.phone);
  late final _email = TextEditingController(text: widget.initial?.email);
  late final _website = TextEditingController(text: widget.initial?.website);

  @override
  void dispose() {
    for (final c in [_name, _title, _company, _phone, _email, _website]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      BusinessCard(
        name: _name.text.trim(),
        title: _title.text.trim(),
        company: _company.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        website: _website.text.trim(),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType? type,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My card'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Name', required: true),
            _field(_title, 'Title'),
            _field(_company, 'Company'),
            _field(_phone, 'Phone', type: TextInputType.phone),
            _field(_email, 'Email', type: TextInputType.emailAddress),
            _field(_website, 'Website', type: TextInputType.url),
          ],
        ),
      ),
    );
  }
}

/// Shows the card as a QR code, and on Android also makes the phone act as
/// an NFC tag for as long as this page is open.
class SharePage extends StatefulWidget {
  const SharePage({super.key, required this.card});

  final BusinessCard card;

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final _share = NfcShare();
  bool? _nfcSharing;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final supported = await _share.isSupported();
    if (supported) await _share.setCard(widget.card.toLink(), sharing: true);
    if (mounted) setState(() => _nfcSharing = supported);
  }

  @override
  void dispose() {
    _share.setCard(null, sharing: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String hint;
    if (_nfcSharing == null) {
      hint = '';
    } else if (_nfcSharing!) {
      hint =
          'Ready to tap. Keep this screen open and touch the backs of the '
          'two phones together. The other phone should be on its Receive screen.';
    } else if (Platform.isIOS) {
      hint =
          'iPhones can\'t send by tap yet. Let the other person scan this '
          'code, or tap their Android phone from your Receive screen.';
    } else {
      hint =
          'This phone can\'t send by tap. Let the other person scan this code.';
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Share my card')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_nfcSharing == true) const Icon(Icons.nfc, size: 64),
          Text(hint, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Center(
            child: QrImageView(
              data: widget.card.toLink(),
              size: 240,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Listens for a tapped card over NFC, or scans a QR code. Pops with every
/// card received while open.
class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  final _nfc = NfcReceive();
  final List<BusinessCard> _cards = [];
  bool _nfcAvailable = false;
  String _status = 'Checking NFC…';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _nfcAvailable = await _nfc.isAvailable();
    if (!mounted) return;
    if (!_nfcAvailable) {
      setState(
        () => _status = 'NFC is off or not available. Use the QR scanner.',
      );
      return;
    }
    // Android listens in the background while this page is open. iOS shows a
    // system sheet, so it starts only when the user asks.
    if (Platform.isAndroid) {
      await _listen();
    } else {
      setState(
        () => _status =
            'Press "Read by tap", then hold the top of '
            'your iPhone to the back of the other phone.',
      );
    }
  }

  Future<void> _listen() async {
    setState(() => _status = 'Hold the back of this phone to the other phone.');
    await _nfc.start(onLink: _onLink, onError: _onError);
  }

  void _onLink(String link) {
    final card = BusinessCard.fromLink(link);
    if (card == null) {
      _onError('That isn\'t an eBuCard card.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _cards.insert(0, card);
      _status = 'Got ${card.name}\'s card.';
    });
  }

  void _onError(String message) {
    if (mounted) setState(() => _status = message);
  }

  Future<void> _scanQr() async {
    await _nfc.stop();
    if (!mounted) return;
    final link = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const QrScanPage()));
    if (link != null) _onLink(link);
    if (_nfcAvailable && Platform.isAndroid) await _listen();
  }

  @override
  void dispose() {
    _nfc.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(List.of(_cards));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Receive a card')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.contactless, size: 64),
            const SizedBox(height: 12),
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (_nfcAvailable && Platform.isIOS)
              FilledButton.icon(
                onPressed: _listen,
                icon: const Icon(Icons.nfc),
                label: const Text('Read by tap'),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _scanQr,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR code'),
            ),
            const SizedBox(height: 24),
            for (final card in _cards) CardView(card: card),
          ],
        ),
      ),
    );
  }
}

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && BusinessCard.fromLink(value) != null) {
        _done = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a card')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
