import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meditrack/app.dart';
import 'package:meditrack/providers/medicine_provider.dart';

void main() {
  testWidgets('shows the empty therapy dashboard state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: MedicineProvider(),
        child: const MyApp(),
      ),
    );

    // Il saluto e' time-aware, quindi il test verifica il nome da solo.
    expect(find.text('Utente'), findsOneWidget);
    expect(find.text('Nessuna terapia ancora'), findsOneWidget);
    expect(find.text('Aggiungi terapia'), findsOneWidget);
  });
}
