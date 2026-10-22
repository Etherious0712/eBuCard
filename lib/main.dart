import 'package:flutter/material.dart';

import 'src/business_card.dart';
import 'src/card_store.dart';
import 'src/pages.dart';

void main() {
  runApp(const EBuCardApp());
}

class EBuCardApp extends StatelessWidget {
  const EBuCardApp({super.key, this.store});

  final CardStore? store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eBuCard',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1E5AA8)),
      home: HomePage(store: store ?? CardStore()),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store});

  final CardStore store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BusinessCard? _myCard;
  bool _loading = true;
  final List<BusinessCard> _received = [];

  @override
  void initState() {
    super.initState();
    widget.store.load().then((card) {
      if (!mounted) return;
      setState(() {
        _myCard = card;
        _loading = false;
      });
    });
  }

  Future<void> _editCard() async {
    final card = await Navigator.of(context).push<BusinessCard>(
      MaterialPageRoute(builder: (_) => EditCardPage(initial: _myCard)),
    );
    if (card == null) return;
    await widget.store.save(card);
    setState(() => _myCard = card);
  }

  Future<void> _share() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => SharePage(card: _myCard!)));
  }

  Future<void> _receive() async {
    final cards = await Navigator.of(context).push<List<BusinessCard>>(
      MaterialPageRoute(builder: (_) => const ReceivePage()),
    );
    if (cards == null || cards.isEmpty) return;
    setState(() => _received.insertAll(0, cards));
  }

  @override
  Widget build(BuildContext context) {
    final myCard = _myCard;
    return Scaffold(
      appBar: AppBar(title: const Text('eBuCard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (myCard == null)
                  Card(
                    child: ListTile(
                      title: const Text('Create your card to start'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editCard,
                    ),
                  )
                else ...[
                  CardView(card: myCard, onEdit: _editCard),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _share,
                          icon: const Icon(Icons.nfc),
                          label: const Text('Share'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _receive,
                          icon: const Icon(Icons.download),
                          label: const Text('Receive'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_received.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Received',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final card in _received) CardView(card: card),
                ],
              ],
            ),
    );
  }
}
