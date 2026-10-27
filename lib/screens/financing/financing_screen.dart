import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/pricing_engine.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../invoice_detail_sheet.dart';

class FinancingScreen extends StatelessWidget {
  const FinancingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).role;
    final (title, subtitle, firstTab, secondTab, firstBody) = switch (role) {
      UserRole.supplier => (
          'Financing',
          'Get paid early on approved invoices',
          'Available offers',
          'Financing History',
          const _SupplierOffers(),
        ),
      UserRole.buyer => (
          'Early Payment',
          'Pay suppliers early and earn a discount',
          'Dynamic discounting',
          'History',
          const _BuyerDynamicDiscount(),
        ),
      UserRole.lender => (
          'Funding',
          'Fund approved invoices from the marketplace',
          'Funding requests',
          'Portfolio',
          const _LenderRequests(),
        ),
    };

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ScreenHeader(title: title, subtitle: subtitle),
          ),
          TabBar(
            labelColor: AppColors.purple,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.purple,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            tabs: [Tab(text: firstTab), Tab(text: secondTab)],
          ),
          Expanded(child: TabBarView(children: [firstBody, const _History()])),
        ],
      ),
    );
  }
}

/// Picks the invoice to finance: the one chosen elsewhere in the app, or the first approved one.
Invoice? _selectedInvoice(AppState state) {
  final approved = state.approvedInvoices;
  if (approved.isEmpty) return null;
  final id = state.financingInvoiceId;
  return approved.firstWhere((i) => i.id == id, orElse: () => approved.first);
}

class _InvoicePicker extends StatelessWidget {
  const _InvoicePicker({required this.selected});
  final Invoice selected;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return DropdownButtonFormField<String>(
      value: selected.id,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Select invoice'),
      items: [
        for (final i in state.approvedInvoices)
          DropdownMenuItem(
            value: i.id,
            child: Text('${i.number} · ${Fmt.money(i.amount)} · ${i.supplierName}', overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: state.selectFinancingInvoice,
    );
  }
}

class _InvoiceDetailsCard extends StatelessWidget {
  const _InvoiceDetailsCard({required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => showInvoiceDetails(context, invoice.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Invoice Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 6),
        InfoRow(label: 'Invoice Amount', value: Fmt.money(invoice.amount), bold: true),
        InfoRow(label: 'Due Date', value: '${Fmt.date(invoice.dueDate)} (${invoice.daysToDue()} days)'),
        InfoRow(label: 'Buyer', value: invoice.buyerName),
        InfoRow(label: 'Supplier', value: invoice.supplierName),
      ]),
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.risk});
  final RiskAssessment risk;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.lavenderLight,
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.purple,
            child: Text(risk.grade, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
          title: Text('Risk-based pricing · score ${risk.score}/100',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          subtitle: const Text('Rates come from the buyer\'s payment history', style: TextStyle(fontSize: 12)),
          childrenPadding: const EdgeInsets.only(bottom: 12, right: 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final f in risk.factors)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text('• $f', style: const TextStyle(fontSize: 12))),
            const SizedBox(height: 6),
            Text('Risk premium: +${Fmt.percent(risk.monthlyPremium, digits: 1)} per month on top of partner base rates',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.best, required this.actionLabel, required this.onSelect});

  final FinancingOffer offer;
  final bool best;
  final String actionLabel;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: best ? AppColors.purple : AppColors.line, width: best ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.lavenderLight,
                child: Icon(Icons.account_balance, size: 18, color: AppColors.purple)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(offer.partner.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(offer.partner.type, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ]),
            ),
            if (best) const Pill(label: 'Best rate', color: AppColors.green, icon: Icons.star_rounded),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _OfferValue(label: 'You receive', value: Fmt.money(offer.payoutAmount), strong: true),
            _OfferValue(
                label: 'Fee (${Fmt.percent(offer.feeRate, digits: 1)})', value: Fmt.money(offer.feeAmount)),
            _OfferValue(label: 'Payout', value: Fmt.payoutTime(offer.partner.payoutHours)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: best
                ? FilledButton(onPressed: onSelect, child: Text(actionLabel))
                : OutlinedButton(onPressed: onSelect, child: Text(actionLabel)),
          ),
        ]),
      ),
    );
  }
}

class _OfferValue extends StatelessWidget {
  const _OfferValue({required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: strong ? 15 : 13, color: strong ? AppColors.green : AppColors.ink)),
      ]),
    );
  }
}

Future<void> _confirmOffer(BuildContext context, FinancingOffer offer) async {
  final state = AppScope.read(context);
  final ok = await confirmDialog(
    context,
    title: 'Accept ${offer.partner.name}?',
    message: 'Invoice ${offer.invoice.number}\n\n'
        'You receive: ${Fmt.money(offer.payoutAmount)}\n'
        'Fee: ${Fmt.money(offer.feeAmount)} (${Fmt.percent(offer.feeRate, digits: 2)})\n'
        'Payout: ${Fmt.payoutTime(offer.partner.payoutHours)}\n\n'
        'The buyer repays ${offer.partner.name} on the due date.',
    confirmLabel: 'Accept offer',
  );
  if (!ok) return;
  final record = await state.acceptOffer(offer);
  if (context.mounted) {
    showSnack(context, '${Fmt.money(record.payoutAmount)} on the way from ${record.funderName}');
  }
}

// -----------------------------------------------------------------------------
// Supplier: funding-partner marketplace
// -----------------------------------------------------------------------------

class _SupplierOffers extends StatelessWidget {
  const _SupplierOffers();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final invoice = _selectedInvoice(state);
    if (invoice == null) {
      return EmptyState(
        icon: Icons.hourglass_empty,
        message: 'No approved invoices yet.\nOnce a buyer approves an invoice you can get paid early here.',
        action: OutlinedButton(onPressed: () => state.setTab(AppTab.invoices), child: const Text('View invoices')),
      );
    }
    final offers = state.offersFor(invoice);
    return ListView(
      padding: pagePadding,
      children: [
        _InvoicePicker(selected: invoice),
        const SizedBox(height: 12),
        _InvoiceDetailsCard(invoice: invoice),
        const SizedBox(height: 12),
        _RiskCard(risk: state.riskFor(invoice)),
        const SectionHeader(title: 'Available Offers'),
        if (offers.isEmpty)
          const EmptyState(icon: Icons.search_off, message: 'No partner can fund this invoice amount')
        else
          for (var i = 0; i < offers.length; i++)
            _OfferCard(
              offer: offers[i],
              best: i == 0,
              actionLabel: 'Select',
              onSelect: () => _confirmOffer(context, offers[i]),
            ),
        const SizedBox(height: 4),
        const Text('By selecting an offer, you agree to the terms and conditions.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Buyer: dynamic discounting
// -----------------------------------------------------------------------------

class _BuyerDynamicDiscount extends StatefulWidget {
  const _BuyerDynamicDiscount();

  @override
  State<_BuyerDynamicDiscount> createState() => _BuyerDynamicDiscountState();
}

class _BuyerDynamicDiscountState extends State<_BuyerDynamicDiscount> {
  double _annualRate = 0.12;
  bool _paying = false;

  Future<void> _pay(DiscountQuote quote) async {
    final state = AppScope.read(context);
    final ok = await confirmDialog(
      context,
      title: 'Pay ${quote.invoice.number} early?',
      message: 'Pay ${quote.invoice.supplierName} ${Fmt.money(quote.supplierReceives)} today '
          'instead of ${Fmt.money(quote.invoice.amount)} on ${Fmt.date(quote.invoice.dueDate)}.\n\n'
          'Your discount: ${Fmt.money(quote.discount)}',
      confirmLabel: 'Pay now',
    );
    if (!ok || !mounted) return;
    setState(() => _paying = true);
    await state.payEarly(quote);
    if (!mounted) return;
    setState(() => _paying = false);
    showSnack(context, 'Paid early. ${Fmt.money(quote.discount)} saved and reconciled automatically');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final invoice = _selectedInvoice(state);
    if (invoice == null) {
      return EmptyState(
        icon: Icons.task_alt,
        message: 'No approved invoices to pay early.\nApprove invoices first.',
        action: OutlinedButton(
          onPressed: () => state.showInvoices(filter: InvoiceStatus.pendingApproval),
          child: const Text('Review pending invoices'),
        ),
      );
    }
    final quote = state.pricing.dynamicDiscount(invoice: invoice, annualRate: _annualRate);
    final offers = state.offersFor(invoice);
    final bestPartner = offers.isEmpty ? null : offers.first;

    return ListView(
      padding: pagePadding,
      children: [
        _InvoicePicker(selected: invoice),
        const SizedBox(height: 12),
        _InvoiceDetailsCard(invoice: invoice),
        const SectionHeader(title: 'Discount rate'),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Annual discount rate (APR)', style: TextStyle(fontWeight: FontWeight.w700))),
              Text(Fmt.percent(_annualRate),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.purple, fontSize: 16)),
            ]),
            Slider(
              value: _annualRate,
              min: 0.04,
              max: 0.24,
              divisions: 20,
              label: Fmt.percent(_annualRate),
              onChanged: (v) => setState(() => _annualRate = v),
            ),
            InfoRow(label: 'Paid early by', value: '${quote.daysEarly} days'),
            InfoRow(label: 'Your discount', value: Fmt.money(quote.discount), valueColor: AppColors.green, bold: true),
            InfoRow(label: 'Supplier receives today', value: Fmt.money(quote.supplierReceives)),
            InfoRow(label: 'Discount rate', value: Fmt.percent(quote.discountRate, digits: 2)),
          ]),
        ),
        if (bestPartner != null) ...[
          const SizedBox(height: 12),
          NoticeBox(
            icon: Icons.compare_arrows,
            color: AppColors.blue,
            title: 'Compared with the best lender offer',
            lines: [
              '${bestPartner.partner.name} would charge the supplier ${Fmt.money(bestPartner.feeAmount)}',
              quote.discount <= bestPartner.feeAmount
                  ? 'Your offer is ${Fmt.money(bestPartner.feeAmount - quote.discount)} cheaper for the supplier'
                  : 'Your offer costs the supplier ${Fmt.money(quote.discount - bestPartner.feeAmount)} more. Lower the rate to stay competitive',
            ],
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _paying || quote.daysEarly == 0 ? null : () => _pay(quote),
          icon: const Icon(Icons.bolt_rounded),
          label: Text('Pay ${Fmt.money(quote.supplierReceives)} early'),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Lender: funding requests
// -----------------------------------------------------------------------------

class _LenderRequests extends StatelessWidget {
  const _LenderRequests();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final requests = state.approvedInvoices;
    if (requests.isEmpty) {
      return const EmptyState(icon: Icons.inbox_outlined, message: 'No open funding requests right now');
    }
    final focused = state.financingInvoiceId;
    final ordered = [
      ...requests.where((i) => i.id == focused),
      ...requests.where((i) => i.id != focused),
    ];
    return ListView(
      padding: pagePadding,
      children: [
        for (final invoice in ordered) _FundingRequestCard(invoice: invoice, highlighted: invoice.id == focused),
      ],
    );
  }
}

class _FundingRequestCard extends StatelessWidget {
  const _FundingRequestCard({required this.invoice, required this.highlighted});

  final Invoice invoice;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final offers = state.offersFor(invoice);
    final mine = offers.where((o) => o.partner.id == state.user!.organizationId).toList();
    final risk = state.riskFor(invoice);
    final myOffer = mine.isEmpty ? null : mine.first;
    final rank = myOffer == null ? 0 : offers.indexOf(myOffer) + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: highlighted ? AppColors.purple : AppColors.line, width: highlighted ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(invoice.number, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                Text('${invoice.supplierName} → ${invoice.buyerName}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
            Pill(label: 'Grade ${risk.grade}', color: AppColors.purple),
          ]),
          const SizedBox(height: 10),
          InfoRow(label: 'Invoice amount', value: Fmt.money(invoice.amount), bold: true),
          InfoRow(label: 'Matures', value: '${Fmt.date(invoice.dueDate)} (${invoice.daysToDue()} days)'),
          if (myOffer != null) ...[
            InfoRow(label: 'Your price', value: '${Fmt.money(myOffer.feeAmount)} (${Fmt.percent(myOffer.feeRate, digits: 2)})', valueColor: AppColors.green),
            InfoRow(label: 'You advance', value: Fmt.money(myOffer.payoutAmount)),
            InfoRow(label: 'Marketplace rank', value: '#$rank of ${offers.length}'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => _confirmOffer(context, myOffer), child: const Text('Fund now')),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Above your maximum ticket size', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
        ]),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// History (all roles)
// -----------------------------------------------------------------------------

class _History extends StatelessWidget {
  const _History();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final records = state.financings;
    if (records.isEmpty) {
      return const EmptyState(icon: Icons.history, message: 'No financing yet');
    }
    final canSettle = state.role != UserRole.supplier;
    return ListView(
      padding: pagePadding,
      children: [
        for (final r in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => showInvoiceDetails(context, r.invoiceId),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text('${r.invoiceNumber} · ${r.supplierName}',
                        style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                  ),
                  Pill(
                    label: r.status.label,
                    color: r.status == FinancingStatus.settled ? AppColors.blue : AppColors.purple,
                  ),
                ]),
                const SizedBox(height: 4),
                Text('${r.type.label} · ${r.funderName} · ${Fmt.date(r.fundedAt)}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 8),
                Row(children: [
                  _OfferValue(label: 'Invoice', value: Fmt.money(r.invoiceAmount)),
                  _OfferValue(label: 'Paid to supplier', value: Fmt.money(r.payoutAmount), strong: true),
                  _OfferValue(label: r.type == FinancingType.partner ? 'Fee' : 'Discount', value: Fmt.money(r.feeAmount)),
                ]),
                if (canSettle && r.status == FinancingStatus.funded) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => showSettlementDialog(context, r),
                      icon: const Icon(Icons.price_check, size: 18),
                      label: Text(state.role == UserRole.buyer ? 'Pay at maturity' : 'Record settlement'),
                    ),
                  ),
                ],
              ]),
            ),
          ),
      ],
    );
  }
}
