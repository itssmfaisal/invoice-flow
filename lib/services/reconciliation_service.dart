import '../core/formatters.dart';
import '../models/models.dart';

/// Matches the buyer's settlement payment against the financed invoice.
class ReconciliationService {
  const ReconciliationService();

  ReconciliationEntry reconcile({
    required String id,
    required FinancingRecord record,
    required double amountReceived,
    required DateTime settledAt,
  }) {
    final difference = amountReceived - record.invoiceAmount;
    final matched = difference.abs() < 0.01;
    final String note;
    if (matched) {
      note = 'Auto-matched: payment equals invoice amount';
    } else if (difference < 0) {
      note = 'Short payment of ${Fmt.money(-difference)}, sent for review';
    } else {
      note = 'Over payment of ${Fmt.money(difference)}, refund needed';
    }
    return ReconciliationEntry(
      id: id,
      financingId: record.id,
      invoiceNumber: record.invoiceNumber,
      counterparty: record.funderName,
      expectedAmount: record.invoiceAmount,
      receivedAmount: amountReceived,
      settledAt: settledAt,
      matched: matched,
      note: note,
    );
  }
}
