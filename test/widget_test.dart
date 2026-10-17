// Placeholder pour test — lance l'app normalement
import 'package:flutter_test/flutter_test.dart';
import 'package:livraison_app/main.dart';

void main() {
  testWidgets('App se lance', (WidgetTester tester) async {
    await tester.pumpWidget(const LivraisonApp());
    expect(find.text('Livraison App'), findsWidgets);
  });
}
