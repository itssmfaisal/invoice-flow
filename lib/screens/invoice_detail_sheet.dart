import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Mobile version of the "Approve Invoice" side panel.
Future<void> showInvoiceDetails(BuildContext context, String invoiceId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => _InvoiceDetail(invoiceId: invoiceId, controller: controller),
    ),
  );
}

/// Records the buyer's payment at maturity and runs automated reconciliation.
Future<void> showSettlementDialog(BuildContext context, FinancingRecord record) async {
  final controller = TextEditingController(text: record.invoiceAmount.toStringAsFixed(0));
  final amount = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Settle ${record.invoiceNumber}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expected from buyer: ${Fmt.money(record.invoiceAmount)}', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount received', prefixText: '\$ '),
          ),
          const SizedBox(height: 8),
          const Text('The payment is matched to the invoice automatically.',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () => Navigator.pop(context, double.tryParse(controller.text.replaceAll(',', ''))),
          child: const Text('Settle'),
        ),
      ],
    ),
  );
  if (amount == null || !context.mounted) return;
  final entry = await AppScope.read(context).settle(record, amountReceived: amount);
  if (context.mounted) {
    showSnack(context, entry.matched ? 'Settled and reconciled automatically' : 'Settled with exception: ${entry.note}');
  }
}

class _InvoiceDetail extends StatelessWidget {
  const _InvoiceDetail({required this.invoiceId, required this.controller});

  final String invoiceId;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final invoice = state.invoiceById(invoiceId);
    if (invoice == null) return const EmptyState(icon: Icons.search_off, message: 'Invoice not found');
    final financing = state.financingFor(invoice);
    final days = invoice.daysToDue();

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        Center(
          child: Container(
              width: 42, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: Text(
              state.role == UserRole.buyer && invoice.status == InvoiceStatus.pendingApproval
                  ? 'Approve Invoice'
                  : 'Invoice details',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ]),
        const SizedBox(height: 8),
        AppCard(
          color: AppColors.lavenderLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(invoice.number, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
                StatusPill(status: invoice.status),
              ]),
              const SizedBox(height: 4),
              Text(Fmt.money(invoice.amount),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.purple)),
              const SizedBox(height: 8),
              InfoRow(label: 'Supplier', value: invoice.supplierName),
              InfoRow(label: 'Buyer', value: invoice.buyerName),
              InfoRow(label: 'PO number', value: invoice.poNumber),
              InfoRow(label: 'Issue date', value: Fmt.date(invoice.issueDate)),
              InfoRow(
                label: 'Due date',
                value: '${Fmt.date(invoice.dueDate)} (${days >= 0 ? 'in $days days' : '${-days} days ago'})',
              ),
              if (invoice.description.isNotEmpty) InfoRow(label: 'Description', value: invoice.description),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _WorkflowSteps(status: invoice.status),
        const SizedBox(height: 16),
        if (invoice.isFlagged)
          NoticeBox(
            icon: Icons.gpp_maybe_outlined,
            color: AppColors.amber,
            title: 'Fraud & duplicate check: needs review',
            lines: invoice.fraudFlags,
          )
        else
          const NoticeBox(
            icon: Icons.verified_user_outlined,
            color: AppColors.green,
            title: 'Passed fraud & duplicate-invoice checks',
          ),
        if (invoice.rejectionReason != null) ...[
          const SizedBox(height: 10),
          NoticeBox(
              icon: Icons.block, color: AppColors.red, title: 'Rejected', lines: [invoice.rejectionReason!]),
        ],
        const SectionHeader(title: 'Documents'),
        if (invoice.documents.isEmpty)
          const Text('No documents attached', style: TextStyle(color: AppColors.muted))
        else
          for (final doc in invoice.documents)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.red),
              title: Text(doc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text('${doc.sizeKb} KB', style: const TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => showSnack(context, 'Document preview will work once the API is connected'),
            ),
        if (financing != null) ...[
          const SectionHeader(title: 'Financing'),
          AppCard(
            child: Column(children: [
              InfoRow(label: 'Type', value: financing.type.label),
              InfoRow(label: 'Funded by', value: financing.funderName),
              InfoRow(label: 'Paid to supplier', value: Fmt.money(financing.payoutAmount), valueColor: AppColors.green),
              InfoRow(
                  label: financing.type == FinancingType.partner ? 'Fee' : 'Discount',
                  value: '${Fmt.money(financing.feeAmount)} (${Fmt.percent(financing.feeRate, digits: 2)})'),
              InfoRow(label: 'Funded on', value: Fmt.date(financing.fundedAt)),
              InfoRow(label: 'Status', value: financing.status.label),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        _Actions(invoice: invoice, financing: financing),
      ],
    );
  }
}

class _WorkflowSteps extends StatelessWidget {
  const _WorkflowSteps({required this.status});
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    const steps = ['Submitted', 'Approved', 'Financed', 'Paid'];
    final reached = switch (status) {
      InvoiceStatus.pendingApproval => 0,
      InvoiceStatus.approved => 1,
      InvoiceStatus.financed => 2,
      InvoiceStatus.paid => 3,
      InvoiceStatus.rejected => 0,
    };
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: i <= reached && status != InvoiceStatus.rejected ? AppColors.purple : AppColors.line,
              ),
            ),
          Column(children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: status == InvoiceStatus.rejected && i == 1
                  ? AppColors.red
                  : i <= reached
                      ? AppColors.purple
                      : AppColors.line,
              child: Icon(
                status == InvoiceStatus.rejected && i == 1 ? Icons.close : Icons.check,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(status == InvoiceStatus.rejected && i == 1 ? 'Rejected' : steps[i],
                style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ]),
        ],
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.invoice, required this.financing});

  final Invoice invoice;
  final FinancingRecord? financing;

  Future<void> _approve(BuildContext context) async {
    final state = AppScope.read(context);
    if (invoice.isFlagged) {
      final ok = await confirmDialog(context,
          title: 'Approve flagged invoice?',
          message: 'This invoice has fraud-check warnings:\n\n• ${invoice.fraudFlags.join('\n• ')}',
          confirmLabel: 'Approve anyway');
      if (!ok) return;
    }
    await state.approveInvoice(invoice);
    if (context.mounted) showSnack(context, '${invoice.number} approved');
  }

  Future<void> _reject(BuildContext context) async {
    final state = AppScope.read(context);
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject ${invoice.number}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Reason (shared with the supplier)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red, minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    await state.rejectInvoice(invoice, reason);
    if (context.mounted) showSnack(context, '${invoice.number} rejected');
  }

  void _goToFinancing(BuildContext context) {
    AppScope.read(context).openFinancingFor(invoice.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final role = state.role;
    final financing = this.financing;

    if (invoice.status == InvoiceStatus.pendingApproval) {
      if (role == UserRole.buyer) {
        return Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red)),
              onPressed: () => _reject(context),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(onPressed: () => _approve(context), child: const Text('Approve'))),
        ]);
      }
      return const NoticeBox(
          icon: Icons.hourglass_top, color: AppColors.amber, title: 'Waiting for buyer approval');
    }

    if (invoice.status == InvoiceStatus.approved) {
      final label = switch (role) {
        UserRole.buyer => 'Pay early with dynamic discount',
        UserRole.supplier => 'Get paid early',
        UserRole.lender => 'Review funding request',
      };
      return FilledButton.icon(
        onPressed: () => _goToFinancing(context),
        icon: const Icon(Icons.bolt_rounded),
        label: Text(label),
      );
    }

    if (invoice.status == InvoiceStatus.financed && financing != null && financing.status == FinancingStatus.funded) {
      final canSettle = role == UserRole.buyer || (role == UserRole.lender && financing.funderId == state.user!.organizationId);
      if (canSettle) {
        return FilledButton.icon(
          onPressed: () => showSettlementDialog(context, financing),
          icon: const Icon(Icons.price_check),
          label: Text(role == UserRole.buyer ? 'Pay ${financing.funderName} now' : 'Record buyer settlement'),
        );
      }
      return NoticeBox(
        icon: Icons.check_circle_outline,
        color: AppColors.green,
        title: 'Paid early by ${financing.funderName}',
        lines: ['The buyer repays the funder on ${Fmt.date(invoice.dueDate)}. Nothing else to do.'],
      );
    }

    return const SizedBox.shrink();
  }
}
