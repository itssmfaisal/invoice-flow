import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../invoice_detail_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final content = switch (state.role) {
      UserRole.buyer => const _BuyerDashboard(),
      UserRole.supplier => const _SupplierDashboard(),
      UserRole.lender => const _LenderDashboard(),
    };
    return RefreshIndicator(onRefresh: state.refresh, child: content);
  }
}

double _sum(Iterable<Invoice> invoices) => invoices.fold<double>(0, (sum, i) => sum + i.amount);

/// "Recent invoices" block shared by every dashboard.
List<Widget> _recentInvoices(BuildContext context, AppState state, {bool showSupplier = true}) {
  final recent = state.invoices.take(4).toList();
  return [
    SectionHeader(title: 'Recent Invoices', action: 'View all', onAction: () => state.showInvoices()),
    if (recent.isEmpty)
      const EmptyState(icon: Icons.receipt_long_outlined, message: 'No invoices yet')
    else
      for (final invoice in recent)
        InvoiceTile(
          invoice: invoice,
          showSupplier: showSupplier,
          onTap: () => showInvoiceDetails(context, invoice.id),
        ),
  ];
}

// -----------------------------------------------------------------------------
// Buyer: AP / procurement view
// -----------------------------------------------------------------------------

class _BuyerDashboard extends StatelessWidget {
  const _BuyerDashboard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final invoices = state.invoices;
    final pending = invoices.where((i) => i.status == InvoiceStatus.pendingApproval).toList();
    final flagged = pending.where((i) => i.isFlagged).length;
    final financed = state.financings.where((r) => r.type == FinancingType.partner);
    final discounts = state.financings.where((r) => r.type == FinancingType.dynamicDiscount);
    final savings = discounts.fold<double>(0, (sum, r) => sum + r.feeAmount);
    final supplierCount = invoices.map((i) => i.supplierId).toSet().length;

    return ListView(
      padding: pagePadding,
      children: [
        ScreenHeader(title: 'Dashboard', subtitle: 'Welcome back, ${state.user!.name.split(' ').first}'),
        TextField(
          textInputAction: TextInputAction.search,
          onSubmitted: (q) => state.showInvoices(query: q),
          decoration: const InputDecoration(hintText: 'Search invoices...', prefixIcon: Icon(Icons.search)),
        ),
        const SizedBox(height: 14),
        TwoColumnGrid(children: [
          MetricCard(label: 'Total Invoice', value: Fmt.money(_sum(invoices), compact: true), icon: Icons.receipt_long),
          MetricCard(
              label: 'Pending Approval',
              value: Fmt.money(_sum(pending), compact: true),
              icon: Icons.schedule,
              accent: AppColors.amber),
          MetricCard(
            label: 'Financed Amount',
            value: Fmt.money(financed.fold<double>(0, (sum, r) => sum + r.invoiceAmount), compact: true),
            icon: Icons.trending_up,
            accent: AppColors.green,
          ),
          MetricCard(label: 'Suppliers', value: '$supplierCount', icon: Icons.groups_outlined),
        ]),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 14),
          AppCard(
            onTap: () => state.showInvoices(filter: InvoiceStatus.pendingApproval),
            child: Row(children: [
              const CircleAvatar(
                  backgroundColor: AppColors.lavenderLight, child: Icon(Icons.fact_check_outlined, color: AppColors.purple)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${pending.length} invoices need approval',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    flagged > 0 ? '$flagged flagged by fraud & duplicate checks' : 'All passed fraud checks',
                    style: TextStyle(color: flagged > 0 ? AppColors.amber : AppColors.green, fontSize: 12),
                  ),
                ]),
              ),
              const Icon(Icons.chevron_right),
            ]),
          ),
        ],
        const SizedBox(height: 10),
        AppCard(
          onTap: () => state.setTab(AppTab.financing),
          child: Row(children: [
            const CircleAvatar(
                backgroundColor: AppColors.lavenderLight, child: Icon(Icons.savings_outlined, color: AppColors.green)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Dynamic discounting', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${Fmt.money(savings)} saved · ${state.approvedInvoices.length} approved invoices can be paid early',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ]),
            ),
            const Icon(Icons.chevron_right),
          ]),
        ),
        ..._recentInvoices(context, state),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Supplier: liquidity dashboard
// -----------------------------------------------------------------------------

class _SupplierDashboard extends StatelessWidget {
  const _SupplierDashboard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final invoices = state.invoices;
    final open = invoices
        .where((i) => i.status == InvoiceStatus.pendingApproval || i.status == InvoiceStatus.approved)
        .toList();
    final records = state.financings;
    final receivedEarly = records.fold<double>(0, (sum, r) => sum + r.payoutAmount);
    final fees = records.fold<double>(0, (sum, r) => sum + r.feeAmount);
    final avgHours =
        records.isEmpty ? 0.0 : records.fold<double>(0, (sum, r) => sum + r.payoutHours) / records.length;
    final unlockable = state.unlockableCash;

    final buckets = <String, double>{'Due in 0-30 days': 0, 'Due in 31-60 days': 0, 'Due in 61-90 days': 0, 'Due in 90+ days': 0};
    for (final i in open) {
      final days = i.daysToDue();
      final key = days <= 30
          ? 'Due in 0-30 days'
          : days <= 60
              ? 'Due in 31-60 days'
              : days <= 90
                  ? 'Due in 61-90 days'
                  : 'Due in 90+ days';
      buckets[key] = buckets[key]! + i.amount;
    }
    final maxBucket = buckets.values.fold<double>(0, (a, b) => a > b ? a : b);

    return ListView(
      padding: pagePadding,
      children: [
        ScreenHeader(title: 'Dashboard', subtitle: '${state.user!.organizationName} · liquidity'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.purple, Color(0xFF9B5BB3)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cash you can unlock today', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text(Fmt.money(unlockable),
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('From ${state.approvedInvoices.length} approved invoices, instead of waiting 30-90 days',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.purple),
              onPressed: state.approvedInvoices.isEmpty ? null : () => state.setTab(AppTab.financing),
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Get paid early'),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        TwoColumnGrid(children: [
          MetricCard(
              label: 'Outstanding', value: Fmt.money(_sum(open), compact: true), icon: Icons.hourglass_bottom),
          MetricCard(
              label: 'Received early',
              value: Fmt.money(receivedEarly, compact: true),
              icon: Icons.south_west_rounded,
              accent: AppColors.green),
          MetricCard(
              label: 'Financing fees',
              value: Fmt.money(fees, compact: true),
              icon: Icons.percent,
              accent: AppColors.amber,
              caption: receivedEarly == 0 ? null : '${Fmt.percent(fees / (receivedEarly + fees), digits: 2)} avg'),
          MetricCard(
              label: 'Avg time to cash',
              value: records.isEmpty ? '-' : '${(avgHours / 24).toStringAsFixed(1)} days',
              icon: Icons.timer_outlined,
              caption: 'vs 45-day terms'),
        ]),
        const SectionHeader(title: 'Receivables aging'),
        AppCard(
          child: Column(children: [
            for (final entry in buckets.entries)
              BarRow(
                label: entry.key,
                value: Fmt.money(entry.value, compact: true),
                fraction: maxBucket == 0 ? 0 : entry.value / maxBucket,
              ),
          ]),
        ),
        ..._recentInvoices(context, state, showSupplier: false),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Lender: funding portfolio
// -----------------------------------------------------------------------------

class _LenderDashboard extends StatelessWidget {
  const _LenderDashboard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final records = state.financings;
    final outstanding = records.where((r) => r.status == FinancingStatus.funded);
    final settled = records.where((r) => r.status == FinancingStatus.settled);
    final fees = records.fold<double>(0, (sum, r) => sum + r.feeAmount);
    final deployed = records.fold<double>(0, (sum, r) => sum + r.payoutAmount);
    final requests = state.approvedInvoices;
    final risk = state.buyerProfiles.isEmpty ? null : state.pricing.assessBuyer(state.buyerProfiles.first);

    return ListView(
      padding: pagePadding,
      children: [
        ScreenHeader(title: 'Dashboard', subtitle: '${state.user!.organizationName} · portfolio'),
        TwoColumnGrid(children: [
          MetricCard(
              label: 'Outstanding',
              value: Fmt.money(outstanding.fold<double>(0, (s, r) => s + r.invoiceAmount), compact: true),
              icon: Icons.account_balance_wallet_outlined),
          MetricCard(
              label: 'Settled',
              value: Fmt.money(settled.fold<double>(0, (s, r) => s + r.invoiceAmount), compact: true),
              icon: Icons.task_alt,
              accent: AppColors.green),
          MetricCard(
              label: 'Fees earned', value: Fmt.money(fees, compact: true), icon: Icons.percent, accent: AppColors.amber),
          MetricCard(
              label: 'Avg fee rate',
              value: deployed == 0 ? '-' : Fmt.percent(fees / (deployed + fees), digits: 2),
              icon: Icons.show_chart),
        ]),
        const SizedBox(height: 14),
        AppCard(
          onTap: () => state.setTab(AppTab.financing),
          child: Row(children: [
            const CircleAvatar(
                backgroundColor: AppColors.lavenderLight, child: Icon(Icons.inbox_outlined, color: AppColors.purple)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${requests.length} funding requests', style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${Fmt.money(_sum(requests), compact: true)} of approved invoices in the marketplace',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right),
          ]),
        ),
        if (risk != null) ...[
          SectionHeader(title: 'Buyer risk: ${state.buyerProfiles.first.name}'),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.purple,
                  child: Text(risk.grade,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Risk score ${risk.score}/100', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('Premium +${Fmt.percent(risk.monthlyPremium, digits: 1)} / month',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              for (final f in risk.factors)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• $f', style: const TextStyle(fontSize: 12)),
                ),
            ]),
          ),
        ],
        ..._recentInvoices(context, state),
      ],
    );
  }
}
