// Basic Flutter widget test for Butterfly AR app.

import 'package:flutter_test/flutter_test.dart';

import 'package:butterflyar/main.dart';

void main() {
  testWidgets('App loads correctly smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ButterflyARApp());

    // Verify that our app title is displayed.
    expect(find.text('Butterfly AR'), findsOneWidget);
    expect(
      find.text('Explora mariposas en Realidad Aumentada'),
      findsOneWidget,
    );

    // Verify that main action buttons are present.
    expect(find.text('Escanear QR'), findsOneWidget);
    expect(find.text('Explorar Especies'), findsOneWidget);
    expect(find.text('Configuración'), findsOneWidget);
  });
}
