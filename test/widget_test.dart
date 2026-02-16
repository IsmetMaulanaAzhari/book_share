import 'package:flutter_test/flutter_test.dart';
import 'package:book_share/main.dart';

void main() {
  testWidgets('App should build without error', (WidgetTester tester) async {
    await tester.pumpWidget(const BookShareApp());
    expect(find.text('Cari Buku di Sekitar'), findsOneWidget);
  });
}
