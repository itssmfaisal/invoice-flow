import 'invoice.dart';
import 'party.dart';

/// A price quote from one funding partner for one invoice.
class FinancingOffer {
  const FinancingOffer({
    required this.partner,
    required this.invoice,
    required this.feeRate,
    required this.feeAmount,
    required this.payoutAmount,
    required this.riskGrade,
  });

  final FundingPartner partner;
  final Invoice invoice;
  final double feeRate;
  final double feeAmount;
  final double payoutAmount;
  final String riskGrade;
}

enum FinancingType {
  partner('Partner financing'),
  dynamicDiscount('Dynamic discount');

  const FinancingType(this.label);
  final String label;
}

enum FinancingStatus {
  funded('Funded'),
  settled('Settled');

  const FinancingStatus(this.label);
  final String label;
}

class FinancingRecord {
  const FinancingRecord({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.supplierId,
    required this.supplierName,
    required this.funderId,
    required this.funderName,
    required this.type,
    required this.invoiceAmount,
    required this.feeAmount,
    required this.payoutAmount,
    required this.payoutHours,
    required this.fundedAt,
    required this.status,
    this.settledAt,
  });

  final String id;
  final String invoiceId;
  final String invoiceNumber;
  final String supplierId;
  final String supplierName;

  /// Funding partner id, or the buyer id for dynamic discounting.
  final String funderId;
  final String funderName;
  final FinancingType type;
  final double invoiceAmount;
  final double feeAmount;
  final double payoutAmount;
  final int payoutHours;
  final DateTime fundedAt;
  final FinancingStatus status;
  final DateTime? settledAt;

  double get feeRate => invoiceAmount == 0 ? 0 : feeAmount / invoiceAmount;

  FinancingRecord copyWith({FinancingStatus? status, DateTime? settledAt}) => FinancingRecord(
        id: id,
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        supplierId: supplierId,
        supplierName: supplierName,
        funderId: funderId,
        funderName: funderName,
        type: type,
        invoiceAmount: invoiceAmount,
        feeAmount: feeAmount,
        payoutAmount: payoutAmount,
        payoutHours: payoutHours,
        fundedAt: fundedAt,
        status: status ?? this.status,
        settledAt: settledAt ?? this.settledAt,
      );
}

class ReconciliationEntry {
  const ReconciliationEntry({
    required this.id,
    required this.financingId,
    required this.invoiceNumber,
    required this.counterparty,
    required this.expectedAmount,
    required this.receivedAmount,
    required this.settledAt,
    required this.matched,
    required this.note,
  });

  final String id;
  final String financingId;
  final String invoiceNumber;
  final String counterparty;
  final double expectedAmount;
  final double receivedAmount;
  final DateTime settledAt;
  final bool matched;
  final String note;

  double get difference => receivedAmount - expectedAmount;

  ReconciliationEntry copyWith({bool? matched, String? note}) => ReconciliationEntry(
        id: id,
        financingId: financingId,
        invoiceNumber: invoiceNumber,
        counterparty: counterparty,
        expectedAmount: expectedAmount,
        receivedAmount: receivedAmount,
        settledAt: settledAt,
        matched: matched ?? this.matched,
        note: note ?? this.note,
      );
}
