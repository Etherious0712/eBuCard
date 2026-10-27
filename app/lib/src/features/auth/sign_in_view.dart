// The sign-in form: email + password (sign in or create an account),
// "Forgot password?", and Apple/Google buttons when they are configured.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/account_providers.dart';
import '../../account/identity_sign_in.dart';
import '../../l10n/generated/app_localizations.dart';
import 'api_error_text.dart';

/// Sign in or create an account.
class SignInView extends ConsumerStatefulWidget {
  /// Creates the form.
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

/// Form fields and the in-progress/error state.
class _SignInViewState extends ConsumerState<SignInView> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Creating a new account rather than signing in.
  bool _creating = false;
  bool _showPassword = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Runs [action], showing progress and any error under the form.
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = apiErrorText(AppLocalizations.of(context), e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Signs in or registers with the email and password entered.
  Future<void> _submit() => _run(() {
    final auth = ref.read(authProvider.notifier);
    return _creating
        ? auth.register(_email.text, _password.text)
        : auth.signIn(_email.text, _password.text);
  });

  /// Asks for an email and sends a password-reset link.
  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context);
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(initialEmail: _email.text),
    );
    if (email == null || email.trim().isEmpty || !mounted) return;
    await _run(() async {
      await ref.read(authProvider.notifier).requestPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.resetEmailSent)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final providers = ref.watch(identitySignInProvider).available;
    return AutofillGroup(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (ref.read(authProvider.notifier).sessionWasExpired)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.sessionExpired,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Text(l10n.signInIntro),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l10n.signIn)),
              ButtonSegment(value: true, label: Text(l10n.createAccount)),
            ],
            selected: {_creating},
            onSelectionChanged: (s) => setState(() {
              _creating = s.first;
              _error = null;
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l10n.email),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: !_showPassword,
            autofillHints: [
              if (_creating)
                AutofillHints.newPassword
              else
                AutofillHints.password,
            ],
            onSubmitted: (_) => _busy ? null : _submit(),
            decoration: InputDecoration(
              labelText: l10n.password,
              helperText: _creating ? l10n.passwordHint : null,
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: _showPassword ? l10n.hidePassword : l10n.showPassword,
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_creating ? l10n.createAccount : l10n.signIn),
          ),
          if (!_creating)
            TextButton(
              onPressed: _busy ? null : _forgotPassword,
              child: Text(l10n.forgotPassword),
            ),
          if (providers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.orContinueWith, textAlign: TextAlign.center),
            const SizedBox(height: 8),
          ],
          if (providers.contains(IdentityProviderKind.apple))
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => ref
                          .read(authProvider.notifier)
                          .signInWith(IdentityProviderKind.apple),
                    ),
              icon: const Icon(Icons.apple),
              label: Text(l10n.continueWithApple),
            ),
          if (providers.contains(IdentityProviderKind.google))
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => ref
                          .read(authProvider.notifier)
                          .signInWith(IdentityProviderKind.google),
                    ),
              icon: const Icon(Icons.g_mobiledata),
              label: Text(l10n.continueWithGoogle),
            ),
        ],
      ),
    );
  }
}

/// Asks for the email to send a reset link to. Owns its text controller,
/// so it is disposed only after the dialog has fully closed.
class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  /// Pre-filled from the sign-in form.
  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

/// Holds the email field.
class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  late final _email = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.resetPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.resetPasswordMessage),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.email),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _email.text),
          child: Text(l10n.send),
        ),
      ],
    );
  }
}
