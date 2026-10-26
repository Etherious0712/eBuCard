import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/locale_resolution.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/cards/card_editor_screen.dart';
import 'features/cards/my_cards_screen.dart';
import 'features/exchange/exchange_screen.dart';
import 'features/inbox/inbox_screen.dart';
import 'home_shell.dart';
import 'l10n/generated/app_localizations.dart';

final _router = GoRouter(
  initialLocation: '/cards',
  routes: [
    GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
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
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/inbox', builder: (_, _) => const InboxScreen()),
          ],
        ),
      ],
    ),
  ],
);

class EBuCardApp extends StatelessWidget {
  const EBuCardApp({super.key});

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
