import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/widgets/medora_3d_asset.dart';

/// Un asset 3D mancante o non caricabile non deve mai far crashare la UI:
/// deve degradare a uno spazio vuoto della stessa dimensione.
void main() {
  testWidgets('a missing asset degrades to an empty box instead of throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Medora3DAsset(
            'assets/images/medora/does_not_exist.png',
            size: 96,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final sizedBox = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(Medora3DAsset),
        matching: find.byType(SizedBox),
      ),
    );
    expect(sizedBox.width, 96);
    expect(sizedBox.height, 96);
  });
}
