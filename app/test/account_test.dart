// Account screens; they exist only with the cloud features on.

import 'package:ebucard/src/account/identity_sign_in.dart';
import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_repository.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/test_app.dart';

void main() {
  late AppDatabase db;
  late FakeServer server;

  setUp(() {
    db = memoryDatabase();
    server = FakeServer();
  });
  tearDown(() => db.close());

  /// Lets network and database work started by a tap finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Opens the account screen from My Cards.
  Future<void> openAccount(
    WidgetTester tester, {
    FakeIdentitySignIn? identity,
  }) async {
    await pumpApp(
      tester,
      db: db,
      server: server,
      identity: identity,
      cloud: true,
    );
    await settle(tester);
    await tester.tap(find.byTooltip('Account'));
    await settle(tester);
  }

  /// Fills in the form and taps [button].
  Future<void> submit(
    WidgetTester tester,
    String email,
    String password, {
    String button = 'Sign in',
  }) async {
    await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      password,
    );
    await tester.tap(find.widgetWithText(FilledButton, button));
    await settle(tester);
  }

  testWidgets('signed out: the form explains that sign-in is optional', (
    tester,
  ) async {
    await openAccount(tester);
    expect(find.textContaining('Signing in is optional'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('wrong password shows a clear message', (tester) async {
    server.addUser('a@x.com', 'right password');
    await openAccount(tester);
    await submit(tester, 'a@x.com', 'wrong password');
    expect(find.text('Wrong email or password.'), findsOneWidget);
  });

  testWidgets('create account, confirm the email, then sync runs', (
    tester,
  ) async {
    await openAccount(tester);
    await tester.tap(find.text('Create account').first);
    await settle(tester);
    expect(find.text('At least 8 characters'), findsOneWidget);
    await submit(
      tester,
      'new@x.com',
      'a good password',
      button: 'Create account',
    );

    expect(find.text('new@x.com'), findsOneWidget);
    expect(
      find.text('Confirm your email to turn on sync. We sent you a link.'),
      findsWidgets,
    );

    server.users['new@x.com']!.verified = true;
    await tester.tap(find.text("I've confirmed it"));
    await settle(tester);
    expect(find.text('Email confirmed'), findsOneWidget);
    expect(find.textContaining('Synced'), findsOneWidget);
  });

  testWidgets('an existing email suggests signing in instead', (tester) async {
    server.addUser('a@x.com', 'password!');
    await openAccount(tester);
    await tester.tap(find.text('Create account').first);
    await settle(tester);
    await submit(
      tester,
      'a@x.com',
      'another password',
      button: 'Create account',
    );
    expect(
      find.text('An account with this email already exists. Sign in instead.'),
      findsOneWidget,
    );
  });

  testWidgets('forgot password sends a reset email', (tester) async {
    await openAccount(tester);
    await tester.tap(find.text('Forgot password?'));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'a@x.com',
    );
    await tester.tap(find.text('Send'));
    await settle(tester);
    expect(server.requests, contains('POST /v1/auth/password_reset'));
    expect(
      find.text('If an account uses that email, a reset link is on its way.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'sign out asks first, warns about unsent changes, clears the phone',
    (tester) async {
      server.addUser('a@x.com', 'password!');
      await openAccount(tester);
      await submit(tester, 'a@x.com', 'password!');
      expect(find.text('a@x.com'), findsOneWidget);

      // A change made without connection can't reach the account.
      server.online = false;
      await tester.runAsync(
        () => CardRepository(db).save(
          BusinessCard(
            id: 'c1',
            cardName: 'Work',
            fullName: 'Me',
            emails: const [
              LabeledValue(label: ContactLabel.work, value: 'm@x.com'),
            ],
            updatedAt: DateTime.utc(2026),
          ),
        ),
      );
      await tester.tap(find.text('Sign out'));
      await settle(tester);
      expect(find.text('Sign out?'), findsOneWidget);
      expect(
        find.textContaining("haven't reached your account"),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await settle(tester);
      expect(find.textContaining('Signing in is optional'), findsOneWidget);
      final left = await tester.runAsync(
        () => CardRepository(db).watchAll().first,
      );
      expect(left, isEmpty);
    },
  );

  testWidgets('delete account explains the 30 days, then signs out', (
    tester,
  ) async {
    final user = server.addUser('a@x.com', 'password!');
    await openAccount(tester);
    await submit(tester, 'a@x.com', 'password!');
    await tester.tap(find.text('Delete account'));
    await settle(tester);
    expect(find.textContaining('erased after 30 days'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await settle(tester);
    expect(user.deleted, isTrue);
    expect(find.textContaining('Signing in is optional'), findsOneWidget);
  });

  testWidgets('configured providers show their buttons and sign in', (
    tester,
  ) async {
    final identity = FakeIdentitySignIn()
      ..available = {IdentityProviderKind.google};
    await openAccount(tester, identity: identity);
    expect(find.text('Continue with Apple'), findsNothing);
    await tester.tap(find.text('Continue with Google'));
    await settle(tester);
    expect(find.text('google-user@x.com'), findsOneWidget);
  });

  testWidgets('cancelling the provider sheet stays on the form', (
    tester,
  ) async {
    final identity = FakeIdentitySignIn()
      ..available = {IdentityProviderKind.google}
      ..token = null;
    await openAccount(tester, identity: identity);
    await tester.tap(find.text('Continue with Google'));
    await settle(tester);
    expect(find.textContaining('Signing in is optional'), findsOneWidget);
  });
}
