enum KycStatus {
  verified('Verified'),
  pending('Pending review'),
  rejected('Rejected');

  const KycStatus(this.label);
  final String label;
}

class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.category,
    required this.kycStatus,
    required this.amlCleared,
    required this.joinedAt,
    required this.contactEmail,
  });

  final String id;
  final String name;
  final String category;
  final KycStatus kycStatus;
  final bool amlCleared;
  final DateTime joinedAt;
  final String contactEmail;

  Supplier copyWith({KycStatus? kycStatus, bool? amlCleared}) => Supplier(
        id: id,
        name: name,
        category: category,
        kycStatus: kycStatus ?? this.kycStatus,
        amlCleared: amlCleared ?? this.amlCleared,
        joinedAt: joinedAt,
        contactEmail: contactEmail,
      );
}

/// Payment behaviour of an enterprise buyer. Drives risk-based pricing.
class BuyerProfile {
  const BuyerProfile({
    required this.id,
    required this.name,
    required this.onTimeRate,
    required this.avgDaysLate,
    required this.invoicesPaid,
    required this.yearsTrading,
  });

  final String id;
  final String name;

  /// Share of invoices paid on or before the due date (0..1).
  final double onTimeRate;
  final double avgDaysLate;
  final int invoicesPaid;
  final int yearsTrading;
}

class FundingPartner {
  const FundingPartner({
    required this.id,
    required this.name,
    required this.type,
    required this.monthlyBaseRate,
    required this.payoutHours,
    required this.maxInvoiceAmount,
  });

  final String id;
  final String name;
  final String type;

  /// Base discount per 30 days before risk premium (e.g. 0.015 = 1.5%).
  final double monthlyBaseRate;
  final int payoutHours;
  final double maxInvoiceAmount;
}
