// Feature: open a card link in the app. The app opens here when someone
// taps "Open in eBuCard" on the web card (ebucard://card/receive/<data>,
// the card inside the link), or, with the cloud features on, a server
// link https://<server>/c/<slug> (Android App Links / iOS Universal
// Links). It saves the card to the Inbox and shows it; if that fails, the
// user lands in the Inbox with a message.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../sync/card_links.dart';
import 'receive_card.dart';

/// Receives the card behind a link.
class CardLinkScreen extends ConsumerStatefulWidget {
  /// Opens the server card link with [slug].
  const CardLinkScreen({super.key, required String this.slug}) : data = null;

  /// Opens the offline card [data] (from an `ebucard://` link).
  const CardLinkScreen.offline({super.key, required String this.data})
    : slug = null;

  /// A server link's slug (`/c/<slug>`), or null.
  final String? slug;

  /// An offline link's data, or null.
  final String? data;

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
    final link = widget.data != null
        ? 'ebucard://card/receive/${widget.data}'
        : ref
              .read(sharePayloadProvider)
              .baseUrl
              .replace(path: '/c/${widget.slug}')
              .toString();
    final id = await receiveCard(
      context,
      ref,
      link: link,
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
