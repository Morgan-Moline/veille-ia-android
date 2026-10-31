import 'package:flutter_test/flutter_test.dart';
import 'package:veille_ia/main.dart';

void main() {
  testWidgets('Veille IA app starts', (tester) async {
    await tester.pumpWidget(const VeilleIAApp());
    expect(find.text('VEILLE IA'), findsOneWidget);
  });
}
