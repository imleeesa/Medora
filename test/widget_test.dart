import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meditrack/app.dart';
import 'package:meditrack/providers/medicine_provider.dart';

void main() {
  testWidgets('shows the empty dashboard state', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: MedicineProvider(),
        child: const MyApp(),
      ),
    );

    expect(find.text('Buongiorno, Utente'), findsOneWidget);
    expect(find.text('Non hai ancora aggiunto terapie'), findsOneWidget);
    expect(find.text('Aggiungi Medicina'), findsOneWidget);
  });
}
