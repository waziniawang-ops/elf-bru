import 'package:flutter_test/flutter_test.dart';
import 'package:wife_business/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const WifeBusinessApp());
    expect(find.text('Elf Bru'), findsOneWidget);
  });
}
