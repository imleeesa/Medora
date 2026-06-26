import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/providers/medicine_provider.dart';
import 'package:meditrack/screens/stock_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('restocking below the warning threshold remains stable', (
    tester,
  ) async {
    final provider = _StockTestProvider(_medicine(stockQuantity: 1));

    await _pumpStockScreen(tester, provider);
    await _restock(tester, '1');

    expect(find.text('Restano solo 2 unita'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restocking above the warning threshold clears the warning', (
    tester,
  ) async {
    final provider = _StockTestProvider(_medicine(stockQuantity: 1));

    await _pumpStockScreen(tester, provider);
    await _restock(tester, '10');

    expect(find.text('11 unita disponibili'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restocking accepts decimal quantities below the threshold', (
    tester,
  ) async {
    final provider = _StockTestProvider(_medicine(stockQuantity: 1.5));

    await _pumpStockScreen(tester, provider);
    await _restock(tester, '0.5');

    expect(find.text('Restano solo 2 unita'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid restock quantity leaves the stock unchanged', (
    tester,
  ) async {
    final provider = _StockTestProvider(_medicine(stockQuantity: 1));

    await _pumpStockScreen(tester, provider);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Aggiungi'));
    await tester.pump();

    expect(
      find.text('Inserisci una quantita maggiore di zero'),
      findsOneWidget,
    );
    expect(provider.medicines.single.stockQuantity, 1);
  });
}

Future<void> _pumpStockScreen(
  WidgetTester tester,
  _StockTestProvider provider,
) {
  return tester.pumpWidget(
    ChangeNotifierProvider<MedicineProvider>.value(
      value: provider,
      child: const MaterialApp(home: StockScreen()),
    ),
  );
}

Future<void> _restock(WidgetTester tester, String quantity) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), quantity);
  await tester.tap(find.widgetWithText(FilledButton, 'Aggiungi'));
  await tester.pumpAndSettle();
}

Medicine _medicine({required double stockQuantity}) {
  final now = DateTime(2026, 6, 24);
  return Medicine(
    id: 'medicine-1',
    profileId: 'profile-1',
    therapyId: 'therapy-1',
    name: 'Medicina di prova',
    dose: '1 compressa',
    times: const [],
    daysOfWeek: const [],
    stockQuantity: stockQuantity,
    stockWarningThreshold: 5,
    createdAt: now,
    updatedAt: now,
  );
}

class _StockTestProvider extends MedicineProvider {
  _StockTestProvider(Medicine medicine) : _medicine = medicine;

  Medicine _medicine;

  @override
  List<Medicine> get medicines => [_medicine];

  @override
  Future<void> addStock({
    required String medicineId,
    required double quantity,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity');
    }
    _medicine = _medicine.copyWith(
      stockQuantity: _medicine.stockQuantity + quantity,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }
}
