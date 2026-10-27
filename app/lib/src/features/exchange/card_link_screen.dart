// Feature: open a card link in the app. When someone taps
// https://<server>/c/<slug> on a phone with eBuCard (Android App Links /
// iOS Universal Links), the app opens here, saves the card to the Inbox
// and shows it. If that fails, the user lands in the Inbox with a message.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../sync/card_links.dart';
import 'receive_card.dart';

/// Receives the card behind the link with [slug].
class CardLinkScreen extends ConsumerStatefulWidget {
  /// Opens the card link with [slug].
  const CardLinkScreen({super.key, required this.slug});

  /// The link's slug (`/c/<slug>`).
  final String slug;

  @override
  ConsumerState<CardLinkScreen> createState() => _CardLinkScreenState();
}

/// Starts receiving once the screen is showing.
class _CardLinkScreenState extends ConsumerState<CardLinkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _receive());
  }

  /// Saves the card, then shows it (or the Inbox if it couldn't be saved).
  Future<void> _receive() async {
    if (!mounted) return;
    final link = ref
        .read(sharePayloadProvider)
        .baseUrl
        .replace(path: '/c/${widget.slug}');
    final id = await receiveCard(
      context,
      ref,
      link: link.toString(),
      via: ReceivedVia.link,
    );
    if (!mounted) return;
    context.go(id == null ? '/inbox' : '/inbox/$id');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).openingCard),
        ],
      ),
    ),
  );
}
