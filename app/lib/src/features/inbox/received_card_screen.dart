// Feature: a received card. Shows every detail with tap-to-act (call, email,
// open website), the user's private note, Save to Contacts, and delete.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/link_launcher.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cards/card_labels.dart';

/// Details of one Inbox entry.
class ReceivedCardScreen extends ConsumerStatefulWidget {
  /// Shows the Inbox entry with [entryId].
  const ReceivedCardScreen({super.key, required this.entryId});

  /// Id of the [ReceivedCard] to show.
  final String entryId;

  @override
  ConsumerState<ReceivedCardScreen> createState() => _ReceivedCardScreenState();
}

/// Loads the entry and holds the note being edited.
class _ReceivedCardScreenState extends ConsumerState<ReceivedCardScreen> {
  final _note = TextEditingController();
  ReceivedCard? _entry;
  bool _loading = true;

  /// The note differs from the saved one, so "Save note" is enabled.
  bool _noteChanged = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Reads the entry from the database.
  Future<void> _load() async {
    final entry = await ref
        .read(receivedCardRepositoryProvider)
        .find(widget.entryId);
    if (!mounted) return;
    setState(() {
      _entry = entry;
      _note.text = entry?.note ?? '';
      _loading = false;
    });
  }

  /// Stores the edited note.
  Future<void> _saveNote() async {
    final l10n = AppLocalizations.of(context);
    final updated = _entry!.copyWith(
      note: _note.text.trim(),
      updatedAt: DateTime.now().toUtc(),
    );
    await ref.read(receivedCardRepositoryProvider).save(updated);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _entry = updated;
      _noteChanged = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.noteSaved)));
  }

  /// Opens the phone's new-contact screen pre-filled with this card.
  Future<void> _saveToContacts() async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(contactsServiceProvider).addToContacts(_entry!.card);
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.contactsError)));
    }
  }

  /// Opens [uri] in another app, or says that no app can.
  Future<void> _open(Uri uri) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    bool opened;
    try {
      opened = await ref.read(linkLauncherProvider).open(uri);
    } on PlatformException {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.cantOpenLink)));
    }
  }

  /// Asks for confirmation, then removes the entry and returns to the Inbox.
  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteReceivedTitle),
        content: Text(l10n.deleteReceivedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(receivedCardRepositoryProvider).delete(_entry!.id);
    if (!mounted) return;
    context.go('/inbox');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = _entry;
    if (_loading || entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Text(l10n.cardNotFound),
        ),
      );
    }

    final card = entry.card;
    final theme = Theme.of(context);
    final received = MaterialLocalizations.of(
      context,
    ).formatMediumDate(entry.receivedAt.toLocal());

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.delete,
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(card.fullName, style: theme.textTheme.headlineSmall),
          if (card.jobTitle.isNotEmpty || card.company.isNotEmpty)
            Text(
              [
                card.jobTitle,
                card.company,
              ].where((s) => s.isNotEmpty).join(' · '),
              style: theme.textTheme.titleMedium,
            ),
          const SizedBox(height: 4),
          Text(l10n.receivedOn(received), style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saveToContacts,
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(l10n.saveToContacts),
          ),
          const SizedBox(height: 8),
          for (final p in card.phones)
            _DetailTile(
              icon: Icons.phone_outlined,
              text: p.value,
              label: p.label.text(l10n),
              onTap: () => _open(LinkLauncher.phone(p.value)),
            ),
          for (final e in card.emails)
            _DetailTile(
              icon: Icons.email_outlined,
              text: e.value,
              label: e.label.text(l10n),
              onTap: () => _open(LinkLauncher.email(e.value)),
            ),
          for (final w in card.websites)
            _DetailTile(
              icon: Icons.language,
              text: w,
              onTap: () => _open(LinkLauncher.website(w)),
            ),
          for (final a in card.addresses)
            _DetailTile(
              icon: Icons.place_outlined,
              text: [
                a.street,
                a.city,
                a.region,
                a.postalCode,
                a.country,
              ].where((s) => s.isNotEmpty).join(', '),
              label: a.label.text(l10n),
            ),
          for (final s in card.socialLinks)
            _DetailTile(
              icon: Icons.alternate_email,
              text: s.handleOrUrl,
              label: s.network.text(l10n),
              // Handles (e.g. a WeChat ID) aren't links; only URLs open.
              onTap: s.handleOrUrl.startsWith(RegExp('https?://'))
                  ? () => _open(Uri.parse(s.handleOrUrl))
                  : null,
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 6,
            onChanged: (text) =>
                setState(() => _noteChanged = text.trim() != entry.note),
            decoration: InputDecoration(
              labelText: l10n.note,
              hintText: l10n.noteHint,
              border: const OutlineInputBorder(),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: _noteChanged ? _saveNote : null,
              child: Text(l10n.saveNote),
            ),
          ),
        ],
      ),
    );
  }
}

/// One detail line (phone, email, ...). Tappable when [onTap] is set.
class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.text,
    this.label,
    this.onTap,
  });

  /// Kind of detail.
  final IconData icon;

  /// The value, e.g. the phone number.
  final String text;

  /// Its label, e.g. "Mobile".
  final String? label;

  /// What tapping does; null for plain text.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(
      text,
      style: onTap == null
          ? null
          : TextStyle(color: Theme.of(context).colorScheme.primary),
    ),
    subtitle: label == null ? null : Text(label!),
    onTap: onTap,
  );
}
