// The signed-in account: email confirmation status, sync status with
// "Sync now", sign out and account deletion.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/account.dart';
import '../../account/account_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../sync/sync_controller.dart';
import 'api_error_text.dart';

/// Details and actions for the signed-in [account].
class AccountView extends ConsumerWidget {
  /// Shows [account].
  const AccountView({super.key, required this.account});

  /// The signed-in account.
  final Account account;

  /// Runs [action], showing [done] or the error as a snackbar.
  Future<void> _act(
    BuildContext context,
    Future<void> Function() action, {
    String? done,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorText(l10n, e))));
    }
  }

  /// Asks "Sign out?" (warning about unsent changes) and signs out.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    // Try to send the latest changes first.
    await ref.read(syncControllerProvider.notifier).syncNow();
    final unsent = await ref
        .read(localSyncStateProvider)
        .watchPendingChanges()
        .first;
    if (!context.mounted) return;
    final confirmed = await _confirm(
      context,
      title: l10n.signOutTitle,
      message: unsent > 0
          ? '${l10n.signOutMessage}\n\n${l10n.signOutUnsynced}'
          : l10n.signOutMessage,
      action: l10n.signOut,
    );
    if (confirmed && context.mounted) {
      await _act(context, ref.read(authProvider.notifier).signOut);
    }
  }

  /// Asks for confirmation and requests account deletion.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      context,
      title: l10n.deleteAccountTitle,
      message: l10n.deleteAccountMessage,
      action: l10n.deleteAccount,
    );
    if (confirmed && context.mounted) {
      await _act(context, ref.read(authProvider.notifier).deleteAccount);
    }
  }

  /// A yes/no dialog.
  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sync = ref.watch(syncControllerProvider);
    final auth = ref.read(authProvider.notifier);

    final syncLine = sync.running
        ? l10n.syncing
        : sync.errorCode != null
        ? apiErrorCodeText(l10n, sync.errorCode!)
        : sync.lastSuccess == null
        ? l10n.notSyncedYet
        : l10n.syncedAt(
            TimeOfDay.fromDateTime(sync.lastSuccess!).format(context),
          );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.account_circle_outlined, size: 40),
          title: Text(account.email ?? l10n.account),
          subtitle: Text(
            account.apple
                ? l10n.signedInWithApple
                : account.google
                ? l10n.signedInWithGoogle
                : account.canSync
                ? l10n.emailConfirmed
                : l10n.emailNotConfirmed,
          ),
        ),
        if (!account.canSync)
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _act(
                  context,
                  auth.resendVerification,
                  done: l10n.emailResent,
                ),
                child: Text(l10n.resendEmail),
              ),
              FilledButton(
                onPressed: () => _act(context, () async {
                  final updated = await auth.refreshAccount();
                  if (updated?.canSync ?? false) {
                    await ref.read(syncControllerProvider.notifier).syncNow();
                  }
                }),
                child: Text(l10n.iConfirmed),
              ),
            ],
          ),
        const Divider(height: 32),
        Text(l10n.syncSection, style: theme.textTheme.titleSmall),
        ListTile(
          leading: sync.running
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  sync.errorCode == null
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                ),
          title: Text(syncLine),
          trailing: TextButton(
            onPressed: sync.running
                ? null
                : () => ref.read(syncControllerProvider.notifier).syncNow(),
            child: Text(l10n.syncNow),
          ),
        ),
        const Divider(height: 32),
        OutlinedButton.icon(
          onPressed: () => _signOut(context, ref),
          icon: const Icon(Icons.logout),
          label: Text(l10n.signOut),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _delete(context, ref),
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          child: Text(l10n.deleteAccount),
        ),
      ],
    );
  }
}
