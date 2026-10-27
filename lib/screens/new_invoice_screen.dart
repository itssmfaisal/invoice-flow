import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Supplier submits an invoice. Fraud & duplicate checks run before submission.
class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({super.key});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _amount = TextEditingController();
  final _po = TextEditingController();
  final _description = TextEditingController();
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 60));
  final List<InvoiceDocument> _documents = [];
  bool _saving = false;

  @override
  void dispose() {
    _number.dispose();
    _amount.dispose();
    _po.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool due}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: due ? _dueDate : _issueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (due) {
        _dueDate = picked;
      } else {
        _issueDate = picked;
      }
    });
  }

  void _attach() {
    final name = _number.text.trim().isEmpty ? 'invoice.pdf' : '${_number.text.trim().toLowerCase()}.pdf';
    setState(() => _documents.add(InvoiceDocument(name: _documents.isEmpty ? name : 'attachment_${_documents.length + 1}.pdf', sizeKb: 140)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.read(context);
    final draft = state.draftInvoice(
      number: _number.text,
      amount: double.parse(_amount.text.replaceAll(',', '')),
      issueDate: _issueDate,
      dueDate: _dueDate,
      poNumber: _po.text.trim(),
      description: _description.text.trim(),
      documents: List.of(_documents),
    );

    final check = state.checkInvoice(draft);
    if (check.blocking.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.block, color: AppColors.red),
          title: const Text('Invoice blocked'),
          content: Text('• ${check.blocking.join('\n• ')}'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fix it'))],
        ),
      );
      return;
    }
    if (check.warnings.isNotEmpty) {
      final ok = await confirmDialog(
        context,
        title: 'Flagged for review',
        message: 'The buyer will see these warnings:\n\n• ${check.warnings.join('\n• ')}\n\nSubmit anyway?',
        confirmLabel: 'Submit',
      );
      if (!ok) return;
    }
    if (!mounted) return;

    setState(() => _saving = true);
    final saved = await state.submitInvoice(draft);
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, '${saved.number} sent to ${saved.buyerName} for approval');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New invoice')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const NoticeBox(
              icon: Icons.shield_outlined,
              color: AppColors.blue,
              title: 'Fraud & duplicate checks run automatically before submission',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _number,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Invoice number', hintText: 'INV-2001'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
              validator: (v) {
                final value = double.tryParse((v ?? '').replaceAll(',', ''));
                if (value == null || value <= 0) return 'Enter an amount greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _po,
              decoration: const InputDecoration(labelText: 'Purchase order (PO) number'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required to match the buyer\'s PO' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _DateField(label: 'Issue date', date: _issueDate, onTap: () => _pickDate(due: false))),
              const SizedBox(width: 10),
              Expanded(child: _DateField(label: 'Due date', date: _dueDate, onTap: () => _pickDate(due: true))),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SectionHeader(title: 'Documents'),
            for (final doc in _documents)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.red),
                title: Text(doc.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _documents.remove(doc)),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _attach,
              icon: const Icon(Icons.attach_file),
              label: const Text('Attach invoice PDF'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Submit for approval'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
        child: Text(Fmt.date(date)),
      ),
    );
  }
}
