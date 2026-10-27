import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _Period {
  _Period(this.invoices, this.financings);

  final List<Invoice> invoices;
  final List<FinancingRecord> financings;

  double get totalVolume => invoices.fold<double>(0, (s, i) => s + i.amount);
  double get financeVolume => financings.fold<double>(0, (s, r) => s + r.invoiceAmount);
  int get activeSuppliers => invoices.map((i) => i.supplierId).toSet().length;
  double get avgPayoutDays =>
      financings.isEmpty ? 0.0 : financings.fold<double>(0, (s, r) => s + r.payoutHours) / financings.length / 24;
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late DateTimeRange _range = _defaultRange();

  static DateTimeRange _defaultRange() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: end.subtract(const Duration(days: 89)), end: end);
  }

  bool _inRange(DateTime d, DateTimeRange r) =>
      !d.isBefore(r.start) && d.isBefore(r.end.add(const Duration(days: 1)));

  _Period _period(AppState state, DateTimeRange r) => _Period(
        state.invoices.where((i) => _inRange(i.issueDate, r)).toList(),
        state.financings.where((f) => _inRange(f.fundedAt, r)).toList(),
      );

  double? _change(double current, double previous) => previous == 0 ? null : (current - previous) / previous;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final length = _range.duration + const Duration(days: 1);
    final previousRange = DateTimeRange(start: _range.start.subtract(length), end: _range.start.subtract(const Duration(days: 1)));
    final current = _period(state, _range);
    final previous = _period(state, previousRange);

    final bySupplier = <String, double>{};
    for (final i in current.invoices) {
      bySupplier[i.supplierName] = (bySupplier[i.supplierName] ?? 0) + i.amount;
    }
    final top = bySupplier.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final adoption = current.totalVolume == 0 ? 0.0 : current.financeVolume / current.totalVolume;

    return ListView(
      padding: pagePadding,
      children: [
        const ScreenHeader(title: 'Analytics', subtitle: 'Supply-chain finance performance'),
        OutlinedButton.icon(
          onPressed: _pickRange,
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: Text('${Fmt.date(_range.start)} - ${Fmt.date(_range.end)}'),
        ),
        const SizedBox(height: 14),
        TwoColumnGrid(children: [
          MetricCard(
            label: 'Total volume',
            value: Fmt.money(current.totalVolume, compact: true),
            change: _change(current.totalVolume, previous.totalVolume),
          ),
          MetricCard(
            label: 'Finance volume',
            value: Fmt.money(current.financeVolume, compact: true),
            change: _change(current.financeVolume, previous.financeVolume),
          ),
          MetricCard(
            label: 'Active suppliers',
            value: '${current.activeSuppliers}',
            change: _change(current.activeSuppliers.toDouble(), previous.activeSuppliers.toDouble()),
          ),
          MetricCard(
            label: 'Average payout time',
            value: current.financings.isEmpty ? '-' : '${current.avgPayoutDays.toStringAsFixed(1)} days',
            caption: 'Financing adoption ${Fmt.percent(adoption, digits: 0)}',
          ),
        ]),
        const SectionHeader(title: 'Monthly volume'),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              _Legend(color: AppColors.lavender, label: 'Invoiced'),
              SizedBox(width: 16),
              _Legend(color: AppColors.purple, label: 'Financed'),
            ]),
            const SizedBox(height: 12),
            SizedBox(height: 170, child: _MonthlyChart(invoices: state.invoices, financings: state.financings)),
          ]),
        ),
        const SectionHeader(title: 'Top Suppliers'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: top.isEmpty
              ? const EmptyState(icon: Icons.bar_chart, message: 'No invoices in this period')
              : Column(children: [
                  for (var i = 0; i < top.length && i < 5; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.lavenderLight,
                        child: Text('${i + 1}',
                            style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                      title: Text(top[i].key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      trailing: Text(Fmt.money(top[i].value, compact: true),
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ]),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]);
}

/// Grouped bar chart of the last 6 months.
class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.invoices, required this.financings});

  final List<Invoice> invoices;
  final List<FinancingRecord> financings;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i)];
    bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
    final invoiced = [
      for (final m in months) invoices.where((i) => sameMonth(i.issueDate, m)).fold<double>(0, (s, i) => s + i.amount)
    ];
    final financed = [
      for (final m in months)
        financings.where((f) => sameMonth(f.fundedAt, m)).fold<double>(0, (s, f) => s + f.invoiceAmount)
    ];
    final maxValue = [...invoiced, ...financed].fold<double>(0, (a, b) => a > b ? a : b);

    return LayoutBuilder(builder: (context, constraints) {
      final barArea = constraints.maxHeight - 44;
      double h(double v) => maxValue == 0 ? 0 : (v / maxValue) * barArea;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < months.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(invoiced[i] == 0 ? '' : Fmt.money(invoiced[i], compact: true),
                      style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Bar(height: h(invoiced[i]), color: AppColors.lavender),
                      const SizedBox(width: 3),
                      _Bar(height: h(financed[i]), color: AppColors.purple),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(Fmt.month(months[i]), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: height < 2 ? 2 : height,
        decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
      );
}
