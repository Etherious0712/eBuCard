// Riverpod providers for accounts and the server connection. Tests replace
// [httpClientProvider], [sessionStoreProvider] and [identitySignInProvider].

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../data/providers.dart';
import '../sync/local_sync_state.dart';
import 'account.dart';
import 'api_client.dart';
import 'auth_controller.dart';
import 'identity_sign_in.dart';
import 'session_store.dart';

/// HTTP client used to talk to the server.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Where the refresh token is kept (secure storage).
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(),
);

/// Apple/Google sign-in sheets.
final identitySignInProvider = Provider<IdentitySignIn>(
  (ref) => DeviceIdentitySignIn(),
);

/// The server connection.
final apiClientProvider = Provider<ApiClient>((ref) {
  final api = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    sessions: ref.watch(sessionStoreProvider),
    client: ref.watch(httpClientProvider),
  );
  api.onSessionExpired = () => ref.read(authProvider.notifier).sessionExpired();
  return api;
});

/// Sync bookkeeping in the local database.
final localSyncStateProvider = Provider<LocalSyncState>(
  (ref) => LocalSyncState(ref.watch(appDatabaseProvider)),
);

/// The signed-in account (null = signed out).
final authProvider = AsyncNotifierProvider<AuthController, Account?>(
  AuthController.new,
);
