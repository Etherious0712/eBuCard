import 'package:ebucard/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts on My Cards and navigates between tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const EBuCardApp());
    await tester.pumpAndSettle();
    expect(find.text('My Cards'), findsWidgets);

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
    await tester.pumpWidget(const EBuCardApp());
    await tester.pumpAndSettle();
    expect(find.text('我的名片'), findsWidgets);
    expect(find.text('收件匣'), findsWidgets);
    expect(find.text('收件箱'), findsNothing);
  });
}
