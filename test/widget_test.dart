
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeapi/main.dart';

void main() {
  testWidgets('Pokemon app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const PokemonApp());

    expect(find.text('Pokemon API Viewer'), findsOneWidget);
    expect(find.text('Explore Pokemon'), findsOneWidget);
  });
}
