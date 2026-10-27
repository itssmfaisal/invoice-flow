import '../core/formatters.dart';
import '../models/models.dart';

class FraudCheckResult {
  const FraudCheckResult({required this.blocking, required this.warnings});

  /// Problems that stop the invoice from being submitted.
  final List<String> blocking;

  /// Suspicious signals; the invoice can go through but is flagged for review.
  final List<String> warnings;

  bool get passed => blocking.isEmpty && warnings.isEmpty;
}

/// Fraud and duplicate-invoice checks run before an invoice enters the AP workflow.
class FraudChecker {
  const FraudChecker();

  FraudCheckResult check({required Invoice candidate, required List<Invoice> existing, Supplier? supplier}) {
    final blocking = <String>[];
    final warnings = <String>[];
    final others = existing.where((i) => i.id != candidate.id && i.supplierId == candidate.supplierId).toList();

    if (candidate.amount <= 0) blocking.add('Amount must be greater than zero');
    if (candidate.dueDate.isBefore(candidate.issueDate)) blocking.add('Due date is before the issue date');

    final number = candidate.number.trim().toLowerCase();
    for (final other in others) {
      if (other.number.trim().toLowerCase() == number) {
        blocking.add('Duplicate invoice number: ${other.number} already exists');
        break;
      }
    }

    for (final other in others) {
      final sameAmount = (other.amount - candidate.amount).abs() < 0.01;
      final closeInTime = other.issueDate.difference(candidate.issueDate).inDays.abs() <= 30;
      if (sameAmount && closeInTime && other.status != InvoiceStatus.rejected) {
        warnings.add('Possible duplicate: same amount as ${other.number} within 30 days');
        break;
      }
    }

    if (others.length >= 3) {
      final average = others.fold<double>(0, (sum, i) => sum + i.amount) / others.length;
      if (candidate.amount > average * 3) {
        warnings.add('Amount is ${(candidate.amount / average).toStringAsFixed(1)}x this supplier\'s average '
            '(${Fmt.money(average, compact: true)})');
      }
    }

    if (supplier != null) {
      if (supplier.kycStatus != KycStatus.verified) warnings.add('Supplier KYC is ${supplier.kycStatus.label.toLowerCase()}');
      if (!supplier.amlCleared) warnings.add('Supplier has an open AML screening alert');
    }

    return FraudCheckResult(blocking: blocking, warnings: warnings);
  }
}
