import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

Color kycColor(KycStatus status) => switch (status) {
      KycStatus.verified => AppColors.green,
      KycStatus.pending => AppColors.amber,
      KycStatus.rejected => AppColors.red,
    };

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String _query = '';
  KycStatus? _kyc;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final suppliers = state.suppliers.where((s) {
      if (_kyc != null && s.kycStatus != _kyc) return false;
      return _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(hintText: 'Search suppliers...', prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('All'), selected: _kyc == null, onSelected: (_) => setState(() => _kyc = null)),
            for (final s in KycStatus.values)
              ChoiceChip(label: Text(s.label), selected: _kyc == s, onSelected: (_) => setState(() => _kyc = s)),
          ]),
          const SizedBox(height: 12),
          for (final supplier in suppliers) _SupplierTile(supplier: supplier),
          if (suppliers.isEmpty) const EmptyState(icon: Icons.groups_outlined, message: 'No suppliers found'),
        ],
      ),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  const _SupplierTile({required this.supplier});
  final Supplier supplier;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final invoices = state.invoicesForSupplier(supplier.id);
    final volume = invoices.fold<double>(0, (s, i) => s + i.amount);
    final open = invoices.where((i) => i.status == InvoiceStatus.pendingApproval || i.status == InvoiceStatus.approved).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => showSupplierDetails(context, supplier.id),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: AppColors.lavenderLight,
            child: Text(supplier.name[0], style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('${supplier.category} · $open open invoices', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                Pill(label: 'KYC ${supplier.kycStatus.label}', color: kycColor(supplier.kycStatus)),
                if (!supplier.amlCleared) const Pill(label: 'AML alert', color: AppColors.red, icon: Icons.warning_amber),
              ]),
            ]),
          ),
          Text(Fmt.money(volume, compact: true), style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

Future<void> showSupplierDetails(BuildContext context, String supplierId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) {
      final state = AppScope.of(context);
      final supplier = state.supplierById(supplierId)!;
      final invoices = state.invoicesForSupplier(supplier.id);
      final financed = state.financings.where((r) => r.supplierId == supplier.id);
      final canManage = state.role == UserRole.buyer;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(supplier.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(supplier.category, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            InfoRow(label: 'Contact', value: supplier.contactEmail),
            InfoRow(label: 'Member since', value: Fmt.date(supplier.joinedAt)),
            InfoRow(label: 'Invoices', value: '${invoices.length}'),
            InfoRow(label: 'Total volume', value: Fmt.money(invoices.fold<double>(0, (s, i) => s + i.amount))),
            InfoRow(label: 'Financed early', value: Fmt.money(financed.fold<double>(0, (s, r) => s + r.invoiceAmount))),
            InfoRow(label: 'KYC', value: supplier.kycStatus.label, valueColor: kycColor(supplier.kycStatus)),
            InfoRow(
              label: 'AML screening',
              value: supplier.amlCleared ? 'Clear' : 'Open alert',
              valueColor: supplier.amlCleared ? AppColors.green : AppColors.red,
            ),
            if (canManage) ...[
              const SizedBox(height: 16),
              if (supplier.kycStatus != KycStatus.verified)
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => state.setKycStatus(supplier, KycStatus.rejected),
                      child: const Text('Reject KYC'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => state.setKycStatus(supplier, KycStatus.verified),
                      child: const Text('Verify KYC'),
                    ),
                  ),
                ]),
              if (!supplier.amlCleared) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => state.clearAmlAlert(supplier),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Mark AML alert as reviewed'),
                  ),
                ),
              ],
            ],
          ]),
        ),
      );
    },
  );
}
