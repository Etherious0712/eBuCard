// The round picture for a person on any card list or header: their photo,
// or their initials on the primary colour when there is none (the same
// initials rule as the web card).

import 'package:flutter/material.dart';

import '../../data/card_image_service.dart';

/// A person's photo, or initials when there is no photo.
class CardAvatar extends StatelessWidget {
  /// Shows [photoUrl] for [name] at [size] logical pixels.
  const CardAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 48,
  });

  /// The person's full name, for the initials.
  final String name;

  /// `file:` or `http(s):` photo, or null.
  final String? photoUrl;

  /// Diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = Container(
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        avatarInitials(name),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontSize: size * 0.38,
        ),
      ),
    );
    // The name is always shown next to the avatar, so it is decorative.
    return ExcludeSemantics(
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: CardImage(uri: photoUrl, fallback: initials),
        ),
      ),
    );
  }
}

/// Up to two initials: the first letters of the first and last word, or
/// the first character of a single word (e.g. a Chinese name).
String avatarInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  final first = words.first.characters.first;
  if (words.length == 1) return first.toUpperCase();
  return (first + words.last.characters.first).toUpperCase();
}
