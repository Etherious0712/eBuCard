// Feature: account. Shows the sign-in form when signed out, and the
// account (email status, sync, sign out, delete) when signed in.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/account_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'account_view.dart';
import 'sign_in_view.dart';

/// `/account`: sign in, or manage the signed-in account.
class AccountScreen extends ConsumerWidget {
  /// Creates the screen.
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final account = auth.value;
    return Scaffold(
      appBar: AppBar(title: Text(account == null ? l10n.signIn : l10n.account)),
      body: auth.isLoading && account == null
          ? const Center(child: CircularProgressIndicator())
          : account == null
          ? const SignInView()
          : AccountView(account: account),
    );
  }
}
