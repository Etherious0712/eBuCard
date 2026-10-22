import 'package:ebucard/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('first launch asks the user to create a card', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const EBuCardApp());
    await tester.pumpAndSettle();

    expect(find.text('Create your card to start'), findsOneWidget);
  });
}
