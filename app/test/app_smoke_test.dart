import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('app starts on My Cards and navigates between tabs', (
    tester,
  ) async {
    final db = memoryDatabase();
    addTearDown(db.close);
    await pumpApp(tester, db: db);
    expect(find.text('My Cards'), findsWidgets);
    expect(
      find.text('You have no cards yet. Create your first business card.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Exchange'));
    await tester.pumpAndSettle();
    expect(find.text('Scan QR code'), findsOneWidget);

    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Cards you receive will appear here.'), findsOneWidget);
  });

  testWidgets('Traditional Chinese strings load for zh_TW', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('zh', 'TW')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final db = memoryDatabase();
    addTearDown(db.close);
    await pumpApp(tester, db: db);
    expect(find.text('我的名片'), findsWidgets);
    expect(find.text('收件匣'), findsWidgets);
    expect(find.text('收件箱'), findsNothing);
  });
}
