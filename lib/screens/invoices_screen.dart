import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'invoice_detail_sheet.dart';
import 'new_invoice_screen.dart';

enum _SortBy {
  recent('Most recent activity'),
  dueDate('Due date (soonest first)'),
  amountHigh('Amount (highest first)'),
  amountLow('Amount (lowest first)');

  const _SortBy(this.label);
  final String label;
}

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _search = TextEditingController();
  AppState? _state;
  _SortBy _sort = _SortBy.recent;
  bool _flaggedOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.read(context);
    if (!identical(state, _state)) {
      _state?.removeListener(_syncSearch);
      _state = state..addListener(_syncSearch);
      _syncSearch();
    }
  }

  /// Keeps the text field in sync when another tab sets the search query.
  void _syncSearch() {
    final query = _state!.invoiceQuery;
    if (_search.text != query) _search.text = query;
  }

  @override
  void dispose() {
    _state?.removeListener(_syncSearch);
    _search.dispose();
    super.dispose();
  }

  List<Invoice> _visible(AppState state) {
    final query = state.invoiceQuery.trim().toLowerCase();
    final list = state.invoices.where((i) {
      if (state.invoiceFilter != null && i.status != state.invoiceFilter) return false;
      if (_flaggedOnly && !i.isFlagged) return false;
      if (query.isEmpty) return true;
      return i.number.toLowerCase().contains(query) ||
          i.supplierName.toLowerCase().contains(query) ||
          i.poNumber.toLowerCase().contains(query) ||
          i.amount.toStringAsFixed(0).contains(query);
    }).toList();
    switch (_sort) {
      case _SortBy.recent:
        break;
      case _SortBy.dueDate:
        list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      case _SortBy.amountHigh:
        list.sort((a, b) => b.amount.compareTo(a.amount));
      case _SortBy.amountLow:
        list.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return list;
  }

  Future<void> _openFilter() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Sort & filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              for (final option in _SortBy.values)
                ListTile(
                  title: Text(option.label),
                  trailing: option == _sort ? const Icon(Icons.check, color: AppColors.purple) : null,
                  onTap: () {
                    setState(() => _sort = option);
                    setSheetState(() {});
                  },
                ),
              const Divider(),
              SwitchListTile(
                title: const Text('Only invoices flagged by fraud checks'),
                value: _flaggedOnly,
                onChanged: (v) {
                  setState(() => _flaggedOnly = v);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(List<Invoice> invoices) async {
    final rows = [
      'Invoice,Supplier,Buyer,Amount,Status,Issue date,Due date,PO',
      for (final i in invoices)
        '${i.number},"${i.supplierName}","${i.buyerName}",${i.amount.toStringAsFixed(2)},${i.status.label},'
            '${i.issueDate.toIso8601String().substring(0, 10)},${i.dueDate.toIso8601String().substring(0, 10)},${i.poNumber}',
    ];
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (mounted) showSnack(context, '${invoices.length} invoices copied to clipboard as CSV');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final visible = _visible(state);
    final total = visible.fold<double>(0, (sum, i) => sum + i.amount);
    final isSupplier = state.role == UserRole.supplier;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isSupplier
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewInvoiceScreen())),
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New invoice'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(
          padding: pagePadding.copyWith(bottom: 96),
          children: [
            ScreenHeader(
              title: 'Invoices',
              subtitle: switch (state.role) {
                UserRole.buyer => 'Review and approve supplier invoices',
                UserRole.supplier => 'Invoices you sent to buyers',
                UserRole.lender => 'Approved invoices open for funding',
              },
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: state.invoiceFilter == null,
                    onTap: () => state.setInvoiceFilter(null),
                  ),
                  for (final status in InvoiceStatus.values)
                    _FilterChip(
                      label: status.label,
                      selected: state.invoiceFilter == status,
                      onTap: () => state.setInvoiceFilter(status),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              onChanged: state.setInvoiceQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search invoices, suppliers, PO...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.invoiceQuery.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.close), onPressed: () => state.setInvoiceQuery('')),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openFilter,
                  icon: Badge(
                    isLabelVisible: _sort != _SortBy.recent || _flaggedOnly,
                    smallSize: 8,
                    child: const Icon(Icons.filter_list, size: 18),
                  ),
                  label: const Text('Filter'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: visible.isEmpty ? null : () => _export(visible),
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('Export'),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Text('${visible.length} invoices · ${Fmt.money(total)}',
                style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 8),
            if (visible.isEmpty)
              const EmptyState(icon: Icons.receipt_long_outlined, message: 'No invoices match your search or filter')
            else
              for (final invoice in visible)
                InvoiceTile(
                  invoice: invoice,
                  showSupplier: !isSupplier,
                  onTap: () => showInvoiceDetails(context, invoice.id),
                ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.purple,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? AppColors.purple : AppColors.line),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
