// Pull-to-refresh that syncs with the account (only while signed in).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../account/account_providers.dart';
import 'sync_controller.dart';

/// Wraps a scrollable [child]; pulling down runs sync when signed in.
class SyncRefresh extends ConsumerWidget {
  /// Wraps [child].
  const SyncRefresh({super.key, required this.child});

  /// A scrollable list.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authProvider).value == null) return child;
    return RefreshIndicator(
      onRefresh: ref.read(syncControllerProvider.notifier).syncNow,
      child: child,
    );
  }
}
