// Root widget: theme, localization and the route table.
//
// Routes:
//   /account             AccountScreen: sign in, or the account (on top of tabs)
//   /cards               MyCardsScreen        ┐
//   /cards/:id/edit      CardEditorScreen     │
//   /exchange            ExchangeScreen       │ bottom-navigation tabs,
//   /exchange/show-qr    ShowQrScreen         │ each keeps its own stack
//   /exchange/scan       ScanScreen           │ (StatefulShellRoute)
//   /exchange/nfc-share  NfcShareScreen       │
//   /exchange/nfc-receive NfcReceiveScreen    │
//   /inbox               InboxScreen          │
//   /inbox/:id           ReceivedCardScreen   ┘
// `/cards/new/edit` opens the editor for a new card.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/locale_resolution.dart';
import 'features/auth/account_screen.dart';
import 'features/cards/card_editor_screen.dart';
import 'features/cards/my_cards_screen.dart';
import 'features/exchange/exchange_screen.dart';
import 'features/exchange/nfc_receive_screen.dart';
import 'features/exchange/nfc_share_screen.dart';
import 'features/exchange/scan_screen.dart';
import 'features/exchange/show_qr_screen.dart';
import 'features/inbox/inbox_screen.dart';
import 'features/inbox/received_card_screen.dart';
import 'home_shell.dart';
import 'l10n/generated/app_localizations.dart';

/// Builds the app's router. A new instance per [EBuCardApp] keeps widget
/// tests independent of each other.
GoRouter _buildRouter() => GoRouter(
  initialLocation: '/cards',
  routes: [
    GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cards',
              builder: (_, _) => const MyCardsScreen(),
              routes: [
                GoRoute(
                  path: ':id/edit',
                  builder: (_, state) =>
                      CardEditorScreen(cardId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/exchange',
              builder: (_, _) => const ExchangeScreen(),
              routes: [
                GoRoute(
                  path: 'show-qr',
                  builder: (_, _) => const ShowQrScreen(),
                ),
                GoRoute(path: 'scan', builder: (_, _) => const ScanScreen()),
                GoRoute(
                  path: 'nfc-share',
                  builder: (_, _) => const NfcShareScreen(),
                ),
                GoRoute(
                  path: 'nfc-receive',
                  builder: (_, _) => const NfcReceiveScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              builder: (_, _) => const InboxScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      ReceivedCardScreen(entryId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

/// The eBuCard application: theme, localization and navigation.
class EBuCardApp extends StatefulWidget {
  /// Creates the app. Must sit below a `ProviderScope`.
  const EBuCardApp({super.key});

  @override
  State<EBuCardApp> createState() => _EBuCardAppState();
}

/// Owns the router so it lives as long as the app.
class _EBuCardAppState extends State<EBuCardApp> {
  final _router = _buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      routerConfig: _router,
      supportedLocales: supportedAppLocales,
      localeResolutionCallback: (locale, _) => resolveAppLocale(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
