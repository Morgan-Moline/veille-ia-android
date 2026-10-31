import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veille_ia/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Veille IA app starts', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const VeilleIAApp());
    expect(find.text('VEILLE IA'), findsOneWidget);
  });
}
