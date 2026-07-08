import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../models/intake_record.dart';
import '../models/therapy.dart';
import '../providers/medicine_provider.dart';
import '../services/history_statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  AdherenceTrendPeriod _trendPeriod = AdherenceTrendPeriod.last7Days;
  String? _trendTherapyId;
  String? _trendMedicineValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(title: const Text('Statistiche')),
      body: SafeArea(
        top: false,
        child: Consumer<MedicineProvider>(
          builder: (context, provider, child) {
            final summary = HistoryStatisticsService.calculate(
              records: provider.intakeHistory,
              therapies: provider.therapies,
              referenceDate: DateTime.now(),
            );
            final medicineOptions = _buildMedicineOptions(
              records: provider.intakeHistory,
              therapies: provider.therapies,
              therapyId: _trendTherapyId,
            );
            final selectedMedicine = medicineOptions
                .where((option) => option.value == _trendMedicineValue)
                .firstOrNull;
            final trend = HistoryStatisticsService.adherenceTrend(
              records: provider.intakeHistory,
              therapies: provider.therapies,
              referenceDate: DateTime.now(),
              period: _trendPeriod,
              therapyId: _trendTherapyId,
              medicineId: selectedMedicine?.medicineId,
              medicineSnapshotName: selectedMedicine?.snapshotName,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                const Text(
                  'Statistiche',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E1E),
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                if (summary.all.totalRecords == 0)
                  const _EmptyStatisticsState()
                else ...[
                  _AdherenceCard(statistics: summary.all),
                  const SizedBox(height: 12),
                  _PeriodCards(summary: summary),
                  const SizedBox(height: 18),
                  _TrendSection(
                    trend: trend,
                    period: _trendPeriod,
                    therapies: provider.therapies,
                    selectedTherapyId: _trendTherapyId,
                    medicineOptions: medicineOptions,
                    selectedMedicineValue: selectedMedicine?.value,
                    onPeriodChanged: (period) {
                      setState(() => _trendPeriod = period);
                    },
                    onTherapyChanged: (therapyId) {
                      setState(() {
                        _trendTherapyId = therapyId;
                        _trendMedicineValue = null;
                      });
                    },
                    onMedicineChanged: (medicineValue) {
                      setState(() => _trendMedicineValue = medicineValue);
                    },
                  ),
                  const SizedBox(height: 18),
                  _StateSummaryCard(statistics: summary.all),
                  const SizedBox(height: 18),
                  _BreakdownSection(
                    title: 'Per medicina',
                    items: summary.byMedicine,
                    emptyText: 'Nessuna medicina nello storico.',
                  ),
                  const SizedBox(height: 18),
                  _BreakdownSection(
                    title: 'Per terapia',
                    items: summary.byTherapy,
                    emptyText: 'Nessuna terapia attribuibile.',
                  ),
                  if (summary.unattributedTherapyRecords > 0) ...[
                    const SizedBox(height: 10),
                    _InfoNote(
                      text:
                          '${summary.unattributedTherapyRecords} record non sono attribuibili a una terapia corrente.',
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<_TrendMedicineOption> _buildMedicineOptions({
    required Iterable<IntakeRecord> records,
    required Iterable<Therapy> therapies,
    required String? therapyId,
  }) {
    final currentMedicines =
        therapies
            .where((therapy) => therapyId == null || therapy.id == therapyId)
            .expand((therapy) => therapy.medicines)
            .toList(growable: false)
          ..sort(
            (first, second) =>
                first.name.toLowerCase().compareTo(second.name.toLowerCase()),
          );
    final options = <_TrendMedicineOption>[
      for (final medicine in currentMedicines)
        _TrendMedicineOption(
          value: 'medicine:${medicine.id}',
          label: medicine.name,
          medicineId: medicine.id,
        ),
    ];

    if (therapyId != null) return options;

    final currentMedicineIds = currentMedicines
        .map((medicine) => medicine.id)
        .toSet();
    final deletedSnapshots = <String, String>{};
    for (final record in records) {
      final snapshot = record.medicineNameSnapshot.trim();
      if (snapshot.isEmpty) continue;
      final medicineId = record.medicineId;
      if (medicineId != null && currentMedicineIds.contains(medicineId)) {
        continue;
      }
      deletedSnapshots.putIfAbsent(snapshot.toLowerCase(), () => snapshot);
    }

    final deletedNames = deletedSnapshots.values.toList()
      ..sort(
        (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
      );
    for (final name in deletedNames) {
      options.add(
        _TrendMedicineOption(
          value: 'snapshot:${name.toLowerCase()}',
          label: '$name (eliminata)',
          snapshotName: name,
        ),
      );
    }

    return options;
  }
}

class _EmptyStatisticsState extends StatelessWidget {
  const _EmptyStatisticsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(
              Icons.insights_outlined,
              color: Color(0xFF2E7D32),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessuna statistica disponibile',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Le statistiche appariranno dopo le prime assunzioni registrate.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendMedicineOption {
  final String value;
  final String label;
  final String? medicineId;
  final String? snapshotName;

  const _TrendMedicineOption({
    required this.value,
    required this.label,
    this.medicineId,
    this.snapshotName,
  });
}

class _TrendSection extends StatelessWidget {
  final List<DailyAdherencePoint> trend;
  final AdherenceTrendPeriod period;
  final List<Therapy> therapies;
  final String? selectedTherapyId;
  final List<_TrendMedicineOption> medicineOptions;
  final String? selectedMedicineValue;
  final ValueChanged<AdherenceTrendPeriod> onPeriodChanged;
  final ValueChanged<String?> onTherapyChanged;
  final ValueChanged<String?> onMedicineChanged;

  const _TrendSection({
    required this.trend,
    required this.period,
    required this.therapies,
    required this.selectedTherapyId,
    required this.medicineOptions,
    required this.selectedMedicineValue,
    required this.onPeriodChanged,
    required this.onTherapyChanged,
    required this.onMedicineChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasEvaluatedData = trend.any((point) => point.evaluatedRecords > 0);

    return _SectionCard(
      title: 'Andamento aderenza',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrendFilters(
            period: period,
            therapies: therapies,
            selectedTherapyId: selectedTherapyId,
            medicineOptions: medicineOptions,
            selectedMedicineValue: selectedMedicineValue,
            onPeriodChanged: onPeriodChanged,
            onTherapyChanged: onTherapyChanged,
            onMedicineChanged: onMedicineChanged,
          ),
          const SizedBox(height: 14),
          if (hasEvaluatedData)
            _AdherenceTrendChart(points: trend)
          else
            const _TrendEmptyState(),
          const SizedBox(height: 10),
          Text(
            'I giorni senza assunzioni valutate restano vuoti e non vengono trattati come 0%.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendFilters extends StatelessWidget {
  final AdherenceTrendPeriod period;
  final List<Therapy> therapies;
  final String? selectedTherapyId;
  final List<_TrendMedicineOption> medicineOptions;
  final String? selectedMedicineValue;
  final ValueChanged<AdherenceTrendPeriod> onPeriodChanged;
  final ValueChanged<String?> onTherapyChanged;
  final ValueChanged<String?> onMedicineChanged;

  const _TrendFilters({
    required this.period,
    required this.therapies,
    required this.selectedTherapyId,
    required this.medicineOptions,
    required this.selectedMedicineValue,
    required this.onPeriodChanged,
    required this.onTherapyChanged,
    required this.onMedicineChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTherapies = therapies.toList(growable: false)
      ..sort(
        (first, second) =>
            first.name.toLowerCase().compareTo(second.name.toLowerCase()),
      );

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 560;
        final itemWidth = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: DropdownButtonFormField<AdherenceTrendPeriod>(
                value: period,
                decoration: const InputDecoration(
                  labelText: 'Periodo',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: AdherenceTrendPeriod.last7Days,
                    child: Text('Ultimi 7 giorni'),
                  ),
                  DropdownMenuItem(
                    value: AdherenceTrendPeriod.last30Days,
                    child: Text('Ultimi 30 giorni'),
                  ),
                  DropdownMenuItem(
                    value: AdherenceTrendPeriod.all,
                    child: Text('Tutto'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) onPeriodChanged(value);
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: DropdownButtonFormField<String>(
                value: selectedTherapyId ?? '',
                decoration: const InputDecoration(
                  labelText: 'Terapia',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Tutte')),
                  for (final therapy in sortedTherapies)
                    DropdownMenuItem(
                      value: therapy.id,
                      child: Text(
                        therapy.isActive
                            ? therapy.name
                            : '${therapy.name} (archiviata)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  onTherapyChanged(
                    value == null || value.isEmpty ? null : value,
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: DropdownButtonFormField<String>(
                value: selectedMedicineValue ?? '',
                decoration: const InputDecoration(
                  labelText: 'Medicina',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Tutte')),
                  for (final option in medicineOptions)
                    DropdownMenuItem(
                      value: option.value,
                      child: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  onMedicineChanged(
                    value == null || value.isEmpty ? null : value,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrendEmptyState extends StatelessWidget {
  const _TrendEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Nessun dato sufficiente per mostrare l\'andamento.',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E1E1E)),
      ),
    );
  }
}

class _AdherenceTrendChart extends StatelessWidget {
  final List<DailyAdherencePoint> points;

  const _AdherenceTrendChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = points.length <= 30
            ? constraints.maxWidth
            : points.length * 30.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth < constraints.maxWidth
                ? constraints.maxWidth
                : chartWidth,
            height: 220,
            child: CustomPaint(painter: _AdherenceTrendPainter(points)),
          ),
        );
      },
    );
  }
}

class _AdherenceTrendPainter extends CustomPainter {
  final List<DailyAdherencePoint> points;
  final DateFormat _labelFormat = DateFormat('d/M');

  _AdherenceTrendPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 36.0;
    const rightPadding = 12.0;
    const topPadding = 12.0;
    const bottomPadding = 36.0;
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartLeft = leftPadding;
    final chartRight = size.width - rightPadding;
    final chartBottom = size.height - bottomPadding;

    final axisPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pointPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;
    final emptyPointPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    for (final value in [0, 50, 100]) {
      final y = _yForPercent(value, chartHeight, topPadding);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      _drawText(
        canvas,
        '$value%',
        Offset(0, y - 8),
        fontSize: 10,
        color: Colors.grey.shade600,
      );
    }

    canvas.drawLine(
      Offset(chartLeft, topPadding),
      Offset(chartLeft, chartBottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(chartLeft, chartBottom),
      Offset(chartRight, chartBottom),
      axisPaint,
    );

    Offset? previousPoint;
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final x = points.length == 1
          ? chartLeft + chartWidth / 2
          : chartLeft + (chartWidth * index / (points.length - 1));
      final percent = point.adherencePercent;

      if (percent == null) {
        previousPoint = null;
        canvas.drawCircle(Offset(x, chartBottom), 2.5, emptyPointPaint);
      } else {
        final currentPoint = Offset(
          x,
          _yForPercent(percent, chartHeight, topPadding),
        );
        if (previousPoint != null) {
          canvas.drawLine(previousPoint, currentPoint, linePaint);
        }
        canvas.drawCircle(currentPoint, 4, pointPaint);
        previousPoint = currentPoint;
      }

      if (_shouldDrawDateLabel(index)) {
        _drawCenteredText(
          canvas,
          _labelFormat.format(point.date),
          Offset(x, chartBottom + 10),
          fontSize: 10,
          color: Colors.grey.shade600,
        );
      }
    }
  }

  double _yForPercent(int percent, double chartHeight, double topPadding) {
    return topPadding + chartHeight * (1 - percent.clamp(0, 100) / 100);
  }

  bool _shouldDrawDateLabel(int index) {
    if (points.length <= 7) return true;
    if (index == 0 || index == points.length - 1) return true;
    final step = points.length <= 30 ? 7 : 14;
    return index % step == 0;
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy));
  }

  @override
  bool shouldRepaint(covariant _AdherenceTrendPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _AdherenceCard extends StatelessWidget {
  final IntakeStatistics statistics;

  const _AdherenceCard({required this.statistics});

  @override
  Widget build(BuildContext context) {
    final hasData = statistics.adherenceDenominator > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8F5E9),
            child: Text(
              hasData ? '${statistics.adherencePercent}%' : '--',
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aderenza generale',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasData
                      ? '${statistics.taken} assunte su ${statistics.evaluatedRecords} assunzioni valutate'
                      : 'Nessun dato valutabile',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.3),
                ),
                if (statistics.totalRecords != statistics.evaluatedRecords) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${statistics.totalRecords} record totali, inclusi promemoria non ancora valutati',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodCards extends StatelessWidget {
  final HistoryStatisticsSummary summary;

  const _PeriodCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 520;
        final width = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _SmallStatCard(title: 'Oggi', statistics: summary.today),
            ),
            SizedBox(
              width: width,
              child: _SmallStatCard(
                title: 'Ultimi 7 giorni',
                statistics: summary.last7Days,
              ),
            ),
            SizedBox(
              width: width,
              child: _SmallStatCard(
                title: 'Ultimi 30 giorni',
                statistics: summary.last30Days,
              ),
            ),
            SizedBox(
              width: width,
              child: _SmallStatCard(title: 'Tutto', statistics: summary.all),
            ),
          ],
        );
      },
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final String title;
  final IntakeStatistics statistics;

  const _SmallStatCard({required this.title, required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            statistics.evaluatedRecords == 0
                ? '--'
                : '${statistics.adherencePercent}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${statistics.totalRecords} record, ${statistics.evaluatedRecords} valutate',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _StateSummaryCard extends StatelessWidget {
  final IntakeStatistics statistics;

  const _StateSummaryCard({required this.statistics});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Per stato',
      child: Column(
        children: [
          _MetricRow(
            label: 'Record totali',
            value: '${statistics.totalRecords}',
          ),
          _MetricRow(
            label: 'Assunzioni valutate',
            value: '${statistics.evaluatedRecords}',
          ),
          _MetricRow(label: 'Assunte', value: '${statistics.taken}'),
          _MetricRow(label: 'Saltate', value: '${statistics.skipped}'),
          _MetricRow(label: 'Dimenticate', value: '${statistics.missed}'),
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  final String title;
  final List<NamedIntakeStatistics> items;
  final String emptyText;

  const _BreakdownSection({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: items.isEmpty
          ? Text(emptyText, style: TextStyle(color: Colors.grey.shade600))
          : Column(
              children: items
                  .map(
                    (item) => _BreakdownRow(
                      name: item.isDeleted
                          ? '${item.name} (eliminata)'
                          : item.name,
                      statistics: item.statistics,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String name;
  final IntakeStatistics statistics;

  const _BreakdownRow({required this.name, required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${statistics.taken} assunte, ${statistics.skipped} saltate, ${statistics.missed} dimenticate',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${statistics.adherencePercent}%',
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String text;

  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1E1E1E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
