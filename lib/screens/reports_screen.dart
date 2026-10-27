import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _export(BuildContext context, List<FinancingRecord> records) async {
    final rows = [
      'Invoice,Supplier,Funder,Type,Invoice amount,Fee,Payout,Funded,Status',
      for (final r in records)
        '${r.invoiceNumber},"${r.supplierName}","${r.funderName}",${r.type.label},${r.invoiceAmount.toStringAsFixed(2)},'
            '${r.feeAmount.toStringAsFixed(2)},${r.payoutAmount.toStringAsFixed(2)},${r.fundedAt.toIso8601String().substring(0, 10)},${r.status.label}',
    ];
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (context.mounted) showSnack(context, 'Financing report copied to clipboard as CSV');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final records = state.financings;
    final entries = state.reconciliations;
    final exceptions = entries.where((e) => !e.matched).length;
    double sum(Iterable<FinancingRecord> rs, double Function(FinancingRecord) f) => rs.fold<double>(0, (s, r) => s + f(r));
    final partner = records.where((r) => r.type == FinancingType.partner);
    final discount = records.where((r) => r.type == FinancingType.dynamicDiscount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: records.isEmpty ? null : () => _export(context, records),
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          TwoColumnGrid(children: [
            MetricCard(label: 'Financed by partners', value: Fmt.money(sum(partner, (r) => r.invoiceAmount), compact: true)),
            MetricCard(
                label: 'Early-paid by buyer', value: Fmt.money(sum(discount, (r) => r.invoiceAmount), compact: true)),
            MetricCard(
                label: 'Partner fees',
                value: Fmt.money(sum(partner, (r) => r.feeAmount), compact: true),
                accent: AppColors.amber),
            MetricCard(
                label: 'Discounts captured',
                value: Fmt.money(sum(discount, (r) => r.feeAmount), compact: true),
                accent: AppColors.green),
          ]),
          const SectionHeader(title: 'Automated reconciliation'),
          NoticeBox(
            icon: exceptions == 0 ? Icons.check_circle_outline : Icons.error_outline,
            color: exceptions == 0 ? AppColors.green : AppColors.amber,
            title: exceptions == 0
                ? 'All ${entries.length} settlements matched automatically'
                : '$exceptions of ${entries.length} settlements need review',
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty) const EmptyState(icon: Icons.receipt_outlined, message: 'No settlements yet'),
          for (final e in entries) _ReconciliationTile(entry: e),
        ],
      ),
    );
  }
}

class _ReconciliationTile extends StatelessWidget {
  const _ReconciliationTile({required this.entry});
  final ReconciliationEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('${entry.invoiceNumber} · ${entry.counterparty}',
                  style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
            ),
            Pill(
              label: entry.matched ? 'Matched' : 'Exception',
              color: entry.matched ? AppColors.green : AppColors.red,
              icon: entry.matched ? Icons.check : Icons.priority_high,
            ),
          ]),
          const SizedBox(height: 6),
          InfoRow(label: 'Expected', value: Fmt.money(entry.expectedAmount)),
          InfoRow(label: 'Received', value: Fmt.money(entry.receivedAmount)),
          InfoRow(label: 'Settled', value: Fmt.date(entry.settledAt)),
          const SizedBox(height: 4),
          Text(entry.note, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          if (!entry.matched) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => AppScope.read(context).resolveReconciliation(entry),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Mark resolved'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
