import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Email + password, Sign in with Apple and Google sign-in.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signIn)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.email_outlined),
            label: Text(l10n.signInWithEmail),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.apple),
            label: Text(l10n.signInWithApple),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.g_mobiledata),
            label: Text(l10n.signInWithGoogle),
          ),
          const SizedBox(height: 24),
          Text(l10n.comingSoon, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
