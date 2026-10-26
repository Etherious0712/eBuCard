import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/card_image_service.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'card_labels.dart';

/// Create (`cardId == 'new'`) or edit a card: core contact fields, photo,
/// company logo and social links.
class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({super.key, required this.cardId});

  final String cardId;

  bool get isNew => cardId == 'new';

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  final _cardName = TextEditingController();
  final _fullName = TextEditingController();
  final _jobTitle = TextEditingController();
  final _company = TextEditingController();
  final _phones = <_ValueRow>[];
  final _emails = <_ValueRow>[];
  final _websites = <TextEditingController>[];
  final _addresses = <_AddressRow>[];
  final _socials = <_SocialRow>[];

  BusinessCard? _original;
  String? _photoUri;
  String? _logoUri;

  /// Images picked in this session that are not saved yet; deleted if the
  /// user leaves without saving.
  final _unsavedImages = <String>{};

  bool _loading = true;
  bool _notFound = false;
  bool _saving = false;
  bool _showErrors = false;

  /// Read once: `ref` can't be used in [dispose].
  late final CardImageService _images;

  @override
  void initState() {
    super.initState();
    _images = ref.read(cardImageServiceProvider);
    if (widget.isNew) {
      // Start a new card with one empty phone and email row to fill in.
      _phones.add(_ValueRow(ContactLabel.mobile));
      _emails.add(_ValueRow(ContactLabel.work));
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final card = await ref.read(cardRepositoryProvider).find(widget.cardId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (card == null) {
        _notFound = true;
        return;
      }
      _original = card;
      _cardName.text = card.cardName;
      _fullName.text = card.fullName;
      _jobTitle.text = card.jobTitle;
      _company.text = card.company;
      _phones.addAll(card.phones.map((p) => _ValueRow(p.label, p.value)));
      _emails.addAll(card.emails.map((e) => _ValueRow(e.label, e.value)));
      _websites.addAll(
        card.websites.map((w) => TextEditingController(text: w)),
      );
      _addresses.addAll(card.addresses.map(_AddressRow.from));
      _socials.addAll(card.socialLinks.map(_SocialRow.from));
      _photoUri = card.photoUrl;
      _logoUri = card.logoUrl;
    });
  }

  @override
  void dispose() {
    for (final uri in _unsavedImages) {
      _images.delete(uri);
    }
    for (final c in [_cardName, _fullName, _jobTitle, _company, ..._websites]) {
      c.dispose();
    }
    for (final r in [..._phones, ..._emails]) {
      r.dispose();
    }
    for (final r in _addresses) {
      r.dispose();
    }
    for (final r in _socials) {
      r.dispose();
    }
    super.dispose();
  }

  BusinessCard _buildCard(AppLocalizations l10n) {
    List<LabeledValue> values(List<_ValueRow> rows) => [
      for (final r in rows)
        if (r.controller.text.trim().isNotEmpty)
          LabeledValue(label: r.label, value: r.controller.text.trim()),
    ];
    final cardName = _cardName.text.trim();
    return BusinessCard(
      id: _original?.id ?? const Uuid().v4(),
      cardName: cardName.isEmpty ? l10n.defaultCardName : cardName,
      fullName: _fullName.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      company: _company.text.trim(),
      phones: values(_phones),
      emails: values(_emails),
      websites: [
        for (final w in _websites)
          if (w.text.trim().isNotEmpty) w.text.trim(),
      ],
      addresses: [
        for (final a in _addresses)
          if (!a.isBlank) a.toAddress(),
      ],
      socialLinks: [
        for (final s in _socials)
          if (s.controller.text.trim().isNotEmpty)
            SocialLink(
              network: s.network,
              handleOrUrl: s.controller.text.trim(),
            ),
      ],
      photoUrl: _photoUri,
      logoUrl: _logoUri,
      shareSlug: _original?.shareSlug,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final card = _buildCard(l10n);
    if (validateCard(card).isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _saving = true);
    await ref.read(cardRepositoryProvider).save(card);

    _unsavedImages.removeAll([?card.photoUrl, ?card.logoUrl]);
    for (final old in [_original?.photoUrl, _original?.logoUrl]) {
      if (old != card.photoUrl && old != card.logoUrl) {
        await _images.delete(old);
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.cardSaved)));
    context.go('/cards');
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCardTitle),
        content: Text(l10n.deleteCardMessage),
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
    final original = _original!;
    await ref.read(cardRepositoryProvider).delete(original.id);
    await _images.delete(original.photoUrl);
    await _images.delete(original.logoUrl);
    if (!mounted) return;
    context.go('/cards');
  }

  Future<void> _editImage({required bool logo}) async {
    final l10n = AppLocalizations.of(context);
    final current = logo ? _logoUri : _photoUri;
    final choice = await showModalBottomSheet<_ImageAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(context, _ImageAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, _ImageAction.camera),
            ),
            if (current != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.removeImage),
                onTap: () => Navigator.pop(context, _ImageAction.remove),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    String? picked;
    if (choice != _ImageAction.remove) {
      try {
        picked = await _images.pickSquareImage(
          choice == _ImageAction.camera
              ? CardImageSource.camera
              : CardImageSource.gallery,
          cropTitle: l10n.cropImage,
        );
      } on PlatformException {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.errorImage)));
        }
        return;
      }
      if (picked == null) return;
      _unsavedImages.add(picked);
    }
    if (!mounted) return;
    setState(() {
      if (logo) {
        _logoUri = picked;
      } else {
        _photoUri = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = Text(widget.isNew ? l10n.newCard : l10n.editCard);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: title),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_notFound) {
      return Scaffold(
        appBar: AppBar(title: title),
        body: Center(child: Text(l10n.cardNotFound)),
      );
    }

    final errors = _showErrors
        ? validateCard(_buildCard(l10n))
        : const <CardValidationError>{};
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: title,
        actions: [
          if (!widget.isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.delete,
              onPressed: _saving ? null : _delete,
            ),
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextField(
            controller: _cardName,
            decoration: InputDecoration(
              labelText: l10n.cardName,
              hintText: l10n.cardNameHint,
            ),
          ),
          _SectionHeader(l10n.profileSection),
          Row(
            children: [
              _ImagePickerTile(
                label: l10n.photo,
                uri: _photoUri,
                icon: Icons.person_outline,
                circle: true,
                onTap: () => _editImage(logo: false),
              ),
              const SizedBox(width: 24),
              _ImagePickerTile(
                label: l10n.logo,
                uri: _logoUri,
                icon: Icons.business_outlined,
                circle: false,
                onTap: () => _editImage(logo: true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _fullName,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _showErrors ? setState(() {}) : null,
            decoration: InputDecoration(
              labelText: '${l10n.fullName} *',
              errorText: errors.contains(CardValidationError.fullNameRequired)
                  ? l10n.errorFullNameRequired
                  : null,
            ),
          ),
          TextField(
            controller: _jobTitle,
            decoration: InputDecoration(labelText: l10n.jobTitle),
          ),
          TextField(
            controller: _company,
            decoration: InputDecoration(labelText: l10n.company),
          ),
          _SectionHeader(l10n.contactSection),
          if (errors.contains(CardValidationError.phoneOrEmailRequired))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.errorPhoneOrEmailRequired,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          _SubHeader(l10n.phones),
          for (final row in _phones)
            _LabeledValueField(
              row: row,
              fieldLabel: l10n.phone,
              keyboardType: TextInputType.phone,
              onChanged: () => setState(() {}),
              onRemove: () => setState(() => _phones.remove(row..dispose())),
            ),
          _AddButton(
            label: l10n.addPhone,
            onPressed: () =>
                setState(() => _phones.add(_ValueRow(ContactLabel.mobile))),
          ),
          _SubHeader(l10n.emails),
          for (final row in _emails)
            _LabeledValueField(
              row: row,
              fieldLabel: l10n.email,
              keyboardType: TextInputType.emailAddress,
              errorText:
                  _showErrors &&
                      row.controller.text.trim().isNotEmpty &&
                      !isValidEmail(row.controller.text)
                  ? l10n.errorInvalidEmail
                  : null,
              onChanged: () => setState(() {}),
              onRemove: () => setState(() => _emails.remove(row..dispose())),
            ),
          _AddButton(
            label: l10n.addEmail,
            onPressed: () =>
                setState(() => _emails.add(_ValueRow(ContactLabel.work))),
          ),
          _SubHeader(l10n.websites),
          for (final controller in _websites)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(labelText: l10n.website),
                  ),
                ),
                _RemoveButton(
                  onPressed: () =>
                      setState(() => _websites.remove(controller..dispose())),
                ),
              ],
            ),
          _AddButton(
            label: l10n.addWebsite,
            onPressed: () =>
                setState(() => _websites.add(TextEditingController())),
          ),
          _SubHeader(l10n.addresses),
          for (final row in _addresses)
            _AddressFields(
              row: row,
              onChanged: () => setState(() {}),
              onRemove: () => setState(() => _addresses.remove(row..dispose())),
            ),
          _AddButton(
            label: l10n.addAddress,
            onPressed: () => setState(() => _addresses.add(_AddressRow())),
          ),
          _SubHeader(l10n.socialLinks),
          for (final row in _socials)
            Row(
              children: [
                DropdownButton<SocialNetwork>(
                  value: row.network,
                  onChanged: (v) => setState(() => row.network = v!),
                  items: [
                    for (final n in SocialNetwork.values)
                      DropdownMenuItem(value: n, child: Text(n.text(l10n))),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: row.controller,
                    decoration: InputDecoration(labelText: l10n.handleOrUrl),
                  ),
                ),
                _RemoveButton(
                  onPressed: () =>
                      setState(() => _socials.remove(row..dispose())),
                ),
              ],
            ),
          _AddButton(
            label: l10n.addSocialLink,
            onPressed: () => setState(
              () => _socials.add(_SocialRow(SocialNetwork.linkedin)),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ImageAction { gallery, camera, remove }

class _ValueRow {
  _ValueRow(this.label, [String text = ''])
    : controller = TextEditingController(text: text);

  ContactLabel label;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}

class _SocialRow {
  _SocialRow(this.network, [String text = ''])
    : controller = TextEditingController(text: text);

  factory _SocialRow.from(SocialLink link) =>
      _SocialRow(link.network, link.handleOrUrl);

  SocialNetwork network;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}

class _AddressRow {
  _AddressRow([PostalAddress address = const PostalAddress()])
    : label = address.label,
      street = TextEditingController(text: address.street),
      city = TextEditingController(text: address.city),
      region = TextEditingController(text: address.region),
      postalCode = TextEditingController(text: address.postalCode),
      country = TextEditingController(text: address.country);

  factory _AddressRow.from(PostalAddress address) => _AddressRow(address);

  ContactLabel label;
  final TextEditingController street;
  final TextEditingController city;
  final TextEditingController region;
  final TextEditingController postalCode;
  final TextEditingController country;

  List<TextEditingController> get _fields => [
    street,
    city,
    region,
    postalCode,
    country,
  ];

  bool get isBlank => _fields.every((c) => c.text.trim().isEmpty);

  PostalAddress toAddress() => PostalAddress(
    label: label,
    street: street.text.trim(),
    city: city.text.trim(),
    region: region.text.trim(),
    postalCode: postalCode.text.trim(),
    country: country.text.trim(),
  );

  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: Text(label),
    ),
  );
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.remove_circle_outline),
    tooltip: AppLocalizations.of(context).remove,
    onPressed: onPressed,
  );
}

class _LabelDropdown extends StatelessWidget {
  const _LabelDropdown({required this.value, required this.onChanged});

  final ContactLabel value;
  final ValueChanged<ContactLabel> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButton<ContactLabel>(
      value: value,
      onChanged: (v) => onChanged(v!),
      items: [
        for (final l in ContactLabel.values)
          DropdownMenuItem(value: l, child: Text(l.text(l10n))),
      ],
    );
  }
}

class _LabeledValueField extends StatelessWidget {
  const _LabeledValueField({
    required this.row,
    required this.fieldLabel,
    required this.keyboardType,
    required this.onChanged,
    required this.onRemove,
    this.errorText,
  });

  final _ValueRow row;
  final String fieldLabel;
  final TextInputType keyboardType;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _LabelDropdown(
          value: row.label,
          onChanged: (v) {
            row.label = v;
            onChanged();
          },
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: TextField(
          controller: row.controller,
          keyboardType: keyboardType,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: fieldLabel,
            errorText: errorText,
          ),
        ),
      ),
      _RemoveButton(onPressed: onRemove),
    ],
  );
}

class _AddressFields extends StatelessWidget {
  const _AddressFields({
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  final _AddressRow row;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget field(TextEditingController c, String label) => TextField(
      controller: c,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(labelText: label),
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
        child: Column(
          children: [
            Row(
              children: [
                _LabelDropdown(
                  value: row.label,
                  onChanged: (v) {
                    row.label = v;
                    onChanged();
                  },
                ),
                const Spacer(),
                _RemoveButton(onPressed: onRemove),
              ],
            ),
            field(row.street, l10n.street),
            field(row.city, l10n.city),
            field(row.region, l10n.region),
            field(row.postalCode, l10n.postalCode),
            field(row.country, l10n.country),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({
    required this.label,
    required this.uri,
    required this.icon,
    required this.circle,
    required this.onTap,
  });

  final String label;
  final String? uri;
  final IconData icon;
  final bool circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = circle
        ? BorderRadius.circular(36)
        : BorderRadius.circular(12);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: radius,
            child: Container(
              width: 72,
              height: 72,
              color: scheme.surfaceContainerHighest,
              child: CardImage(
                uri: uri,
                fallback: Icon(icon, size: 32, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
