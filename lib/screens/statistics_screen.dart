import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medicine_provider.dart';
import '../services/history_statistics_service.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

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
                      ? '${statistics.taken} assunte su ${statistics.adherenceDenominator} registrazioni valutabili'
                      : 'Nessun dato valutabile',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.3),
                ),
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
            '${statistics.adherencePercent}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${statistics.totalRecords} record',
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
            label: 'Totale record',
            value: '${statistics.totalRecords}',
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
