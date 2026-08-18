import 'package:flutter_test/flutter_test.dart';
import 'package:salesgo/main.dart';

void main() {
  testWidgets('SalesGo app launches with login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SalesGoApp());

    expect(find.text('SalesGo'), findsOneWidget);
  });
}
