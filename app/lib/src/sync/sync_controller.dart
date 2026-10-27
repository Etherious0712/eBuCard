// Decides when to sync and reports how it went.
//
// Sync runs automatically while signed in: when the app starts or comes
// back to the foreground, two seconds after any change on this phone, and
// on pull-to-refresh. Only one run happens at a time; a request during a
// run starts one more run afterwards. Without network, changes wait on the
// phone and go out on the next successful run.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../account/account_providers.dart';
import '../account/api_client.dart';
import '../data/providers.dart';
import 'sync_engine.dart';

/// How sync is doing.
class SyncStatus {
  /// Creates a status.
  const SyncStatus({this.running = false, this.lastSuccess, this.errorCode});

  /// A run is in progress.
  final bool running;

  /// When the last run finished successfully.
  final DateTime? lastSuccess;

  /// Why the last run failed (`network`, `email_not_verified`, ...), or
  /// null if it worked.
  final String? errorCode;

  /// A copy with changed fields. Pass [clearError] to reset [errorCode].
  SyncStatus copyWith({
    bool? running,
    DateTime? lastSuccess,
    String? errorCode,
    bool clearError = false,
  }) => SyncStatus(
    running: running ?? this.running,
    lastSuccess: lastSuccess ?? this.lastSuccess,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
  );
}

/// Runs [SyncEngine] at the right moments.
class SyncController extends Notifier<SyncStatus> {
  Timer? _debounce;
  bool _again = false;
  Completer<void>? _current;

  /// Wait after a local change before syncing, so a burst of edits goes
  /// out in one run.
  static const debounce = Duration(seconds: 2);

  @override
  SyncStatus build() {
    final lifecycle = AppLifecycleListener(onResume: requestSync);
    final pending = ref
        .read(localSyncStateProvider)
        .watchPendingChanges()
        .listen((count) {
          if (count > 0) _schedule();
        });
    ref.onDispose(() {
      lifecycle.dispose();
      pending.cancel();
      _debounce?.cancel();
    });
    // Sync once at start-up if already signed in.
    Future.microtask(requestSync);
    return const SyncStatus();
  }

  /// Starts a run soon (debounced).
  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(debounce, requestSync);
  }

  /// Starts a run now, or right after the current one.
  void requestSync() => unawaited(syncNow());

  /// Runs sync (if signed in) and completes when done. Used by
  /// pull-to-refresh and "Sync now".
  Future<void> syncNow() async {
    if (_current != null) {
      _again = true;
      return _current!.future;
    }
    final done = _current = Completer<void>();
    try {
      do {
        _again = false;
        await _runOnce();
      } while (_again);
    } finally {
      _current = null;
      done.complete();
    }
  }

  /// One run, with the checks around it.
  Future<void> _runOnce() async {
    final auth = ref.read(authProvider.notifier);
    var account = ref.read(authProvider).value;
    if (account == null) return;
    state = state.copyWith(running: true);
    try {
      if (!account.canSync) {
        // Maybe the email was confirmed since we last asked.
        account = await auth.refreshAccount();
        if (account == null || !account.canSync) {
          state = state.copyWith(
            running: false,
            errorCode: 'email_not_verified',
          );
          return;
        }
      }
      await SyncEngine(
        api: ref.read(apiClientProvider),
        cards: ref.read(cardRepositoryProvider),
        received: ref.read(receivedCardRepositoryProvider),
        state: ref.read(localSyncStateProvider),
        images: ref.read(cardImageServiceProvider),
      ).run();
      state = state.copyWith(
        running: false,
        lastSuccess: DateTime.now(),
        clearError: true,
      );
    } on ApiError catch (e) {
      state = state.copyWith(running: false, errorCode: e.code);
    }
  }
}

/// Sync status and controls.
final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);
