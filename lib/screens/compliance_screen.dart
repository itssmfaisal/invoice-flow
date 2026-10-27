import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'suppliers_screen.dart';

/// Regulatory requirements: lending/factoring licence, KYC/AML, financial compliance.
class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  bool _screening = false;

  Future<void> _runScreening() async {
    setState(() => _screening = true);
    final state = AppScope.read(context);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final alerts = await state.runAmlScreening();
    if (!mounted) return;
    setState(() => _screening = false);
    showSnack(context, alerts == 0 ? 'AML screening complete: no alerts' : 'AML screening complete: $alerts open alert(s)');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final compliance = state.settings!.compliance;
    // Suppliers only see their own KYC/AML record.
    final suppliers = state.role == UserRole.supplier
        ? state.suppliers.where((s) => s.id == state.user!.organizationId).toList()
        : state.suppliers;
    int count(KycStatus s) => suppliers.where((x) => x.kycStatus == s).length;
    final attention = suppliers.where((s) => s.kycStatus != KycStatus.verified || !s.amlCleared).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Compliance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          AppCard(
            color: AppColors.lavenderLight,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.gavel_rounded, color: AppColors.purple),
                SizedBox(width: 8),
                Text('Lending / factoring licence', style: TextStyle(fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 8),
              InfoRow(label: 'Type', value: compliance.licenseType),
              InfoRow(label: 'Licence no.', value: compliance.licenseNumber),
              InfoRow(label: 'Regulator', value: compliance.regulator),
              InfoRow(label: 'Valid until', value: Fmt.date(compliance.licenseValidUntil), valueColor: AppColors.green),
            ]),
          ),
          const SectionHeader(title: 'KYC overview'),
          TwoColumnGrid(children: [
            MetricCard(label: 'Verified', value: '${count(KycStatus.verified)}', accent: AppColors.green),
            MetricCard(label: 'Pending review', value: '${count(KycStatus.pending)}', accent: AppColors.amber),
            MetricCard(label: 'Rejected', value: '${count(KycStatus.rejected)}', accent: AppColors.red),
            MetricCard(
                label: 'AML alerts', value: '${suppliers.where((s) => !s.amlCleared).length}', accent: AppColors.red),
          ]),
          const SectionHeader(title: 'AML screening'),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sanctions, PEP and adverse-media screening of all suppliers.',
                  style: TextStyle(color: AppColors.ink.withOpacity(0.8), fontSize: 13)),
              const SizedBox(height: 6),
              Text('Last run ${Fmt.relative(compliance.lastAmlScreening)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _screening ? null : _runScreening,
                  icon: _screening
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.policy_outlined),
                  label: Text(_screening ? 'Screening...' : 'Run screening now'),
                ),
              ),
            ]),
          ),
          SectionHeader(title: 'Needs attention (${attention.length})'),
          if (attention.isEmpty)
            const NoticeBox(icon: Icons.check_circle_outline, color: AppColors.green, title: 'All suppliers are cleared'),
          for (final s in attention)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: EdgeInsets.zero,
                onTap: () => showSupplierDetails(context, s.id),
                child: ListTile(
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text([
                    if (s.kycStatus != KycStatus.verified) 'KYC ${s.kycStatus.label.toLowerCase()}',
                    if (!s.amlCleared) 'open AML alert',
                  ].join(' · ')),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
          const SectionHeader(title: 'Financial compliance'),
          const AppCard(
            child: Column(children: [
              _Check('Immutable audit trail for every approval and payment'),
              _Check('Funds held in segregated settlement accounts'),
              _Check('Transaction reporting to the regulator'),
              _Check('Data retention: 7 years'),
              _Check('Encryption at rest and in transit'),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          const Icon(Icons.check_circle, color: AppColors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ]),
      );
}
