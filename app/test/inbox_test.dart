import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/contacts_service.dart';
import 'package:ebucard/src/data/received_card_repository.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

/// A received card for Jane Doe with one of each kind of detail.
final _jane = ReceivedCard(
  id: 'jane',
  card: BusinessCard(
    id: 'c-jane',
    cardName: '',
    fullName: 'Jane Doe',
    jobTitle: 'CEO',
    company: 'Acme',
    phones: const [
      LabeledValue(label: ContactLabel.mobile, value: '+852 9123-4567'),
    ],
    emails: const [
      LabeledValue(label: ContactLabel.work, value: 'jane@acme.com'),
    ],
    websites: const ['acme.com'],
    socialLinks: const [
      SocialLink(network: SocialNetwork.wechat, handleOrUrl: 'janedoe'),
    ],
    updatedAt: DateTime.utc(2026),
  ),
  receivedVia: ReceivedVia.qr,
  receivedAt: DateTime.utc(2026, 3, 2),
  updatedAt: DateTime.utc(2026, 3, 2),
);

/// An older received card from a different company.
final _sam = ReceivedCard(
  id: 'sam',
  card: BusinessCard(
    id: 'c-sam',
    cardName: '',
    fullName: 'Sam Lee',
    company: 'Globex',
    updatedAt: DateTime.utc(2026),
  ),
  receivedVia: ReceivedVia.qr,
  receivedAt: DateTime.utc(2026, 3, 1),
  updatedAt: DateTime.utc(2026, 3, 1),
);

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  /// Stores [entries] and opens the Inbox tab.
  Future<void> openInbox(
    WidgetTester tester,
    List<ReceivedCard> entries, {
    FakeContactsService? contacts,
    FakeLinkLauncher? links,
  }) async {
    await dbCall(tester, () async {
      for (final e in entries) {
        await ReceivedCardRepository(db).save(e);
      }
    });
    await pumpApp(tester, db: db, contacts: contacts, links: links);
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
  }

  /// Waits for database work started by a tap to finish.
  Future<void> settleDb(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists newest first and filters by search', (tester) async {
    await openInbox(tester, [_sam, _jane]);
    final jane = tester.getTopLeft(find.text('Jane Doe'));
    final sam = tester.getTopLeft(find.text('Sam Lee'));
    expect(jane.dy, lessThan(sam.dy), reason: 'newest first');

    await tester.enterText(find.byType(TextField), 'globex');
    await settleDb(tester);
    expect(find.text('Sam Lee'), findsOneWidget);
    expect(find.text('Jane Doe'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nobody');
    await settleDb(tester);
    expect(find.text('No matching cards'), findsOneWidget);
  });

  testWidgets('tapping details calls, emails and opens websites', (
    tester,
  ) async {
    final links = FakeLinkLauncher();
    await openInbox(tester, [_jane], links: links);
    await tester.tap(find.text('Jane Doe'));
    await settleDb(tester);

    await tester.tap(find.text('+852 9123-4567'));
    await tester.tap(find.text('jane@acme.com'));
    await tester.tap(find.text('acme.com'));
    await tester.tap(find.text('janedoe')); // a handle, not a link
    await tester.pumpAndSettle();

    expect(links.opened, [
      Uri.parse('tel:+85291234567'),
      Uri.parse('mailto:jane@acme.com'),
      Uri.parse('https://acme.com'),
    ]);
  });

  testWidgets('Save to Contacts hands the card to the Contacts app', (
    tester,
  ) async {
    final contacts = FakeContactsService();
    await openInbox(tester, [_jane], contacts: contacts);
    await tester.tap(find.text('Jane Doe'));
    await settleDb(tester);
    await tester.tap(find.text('Save to Contacts'));
    await tester.pumpAndSettle();

    expect(contacts.added.single.fullName, 'Jane Doe');
  });

  testWidgets('the private note is saved', (tester) async {
    await openInbox(tester, [_jane]);
    await tester.tap(find.text('Jane Doe'));
    await settleDb(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Private note'),
      'Met at Expo 2026',
    );
    await tester.pump();
    await tester.tap(find.text('Save note'));
    await settleDb(tester);

    final saved = await dbCall(
      tester,
      () => ReceivedCardRepository(db).find('jane'),
    );
    expect(saved!.note, 'Met at Expo 2026');
    expect(find.text('Note saved'), findsOneWidget);
  });

  testWidgets('delete asks first, then removes the card', (tester) async {
    await openInbox(tester, [_jane]);
    await tester.tap(find.text('Jane Doe'));
    await settleDb(tester);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Remove this card from your Inbox?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleDb(tester);

    expect(
      await dbCall(tester, () => ReceivedCardRepository(db).find('jane')),
      isNull,
    );
    expect(find.text('Cards you receive will appear here.'), findsOneWidget);
  });

  test('cards map to the Contacts model with matching labels', () {
    final contact = DeviceContactsService.toContact(_jane.card);
    expect(contact.name?.first, 'Jane');
    expect(contact.name?.last, 'Doe');
    expect(contact.phones.single.label.label, fc.PhoneLabel.mobile);
    expect(contact.emails.single.label.label, fc.EmailLabel.work);
    expect(contact.organizations.single.name, 'Acme');
    expect(contact.organizations.single.jobTitle, 'CEO');
    expect(contact.socialMedias.single.label.customLabel, 'wechat');
  });
}
