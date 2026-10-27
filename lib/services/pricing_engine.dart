import 'dart:math' as math;

import '../core/formatters.dart';
import '../models/models.dart';

class RiskAssessment {
  const RiskAssessment({required this.score, required this.grade, required this.monthlyPremium, required this.factors});

  /// 0 (high risk) .. 100 (low risk).
  final int score;
  final String grade;

  /// Extra monthly rate added on top of a partner's base rate.
  final double monthlyPremium;
  final List<String> factors;
}

class DiscountQuote {
  const DiscountQuote({
    required this.invoice,
    required this.annualRate,
    required this.daysEarly,
    required this.discount,
  });

  final Invoice invoice;
  final double annualRate;
  final int daysEarly;
  final double discount;

  double get supplierReceives => invoice.amount - discount;
  double get discountRate => invoice.amount == 0 ? 0 : discount / invoice.amount;
}

/// Underwriting engine: prices invoices from the buyer's payment history.
class PricingEngine {
  const PricingEngine();

  static const minFeeRate = 0.005;

  RiskAssessment assessBuyer(BuyerProfile buyer) {
    final punctuality = buyer.onTimeRate * 60;
    final lateness = (20 - buyer.avgDaysLate * 2).clamp(0, 20).toDouble();
    final history = (buyer.invoicesPaid / 50).clamp(0, 1).toDouble() * 10;
    final tenure = (buyer.yearsTrading / 10).clamp(0, 1).toDouble() * 10;
    final score = (punctuality + lateness + history + tenure).round().clamp(0, 100).toInt();

    final String grade;
    final double premium;
    if (score >= 85) {
      grade = 'A';
      premium = 0;
    } else if (score >= 70) {
      grade = 'B';
      premium = 0.003;
    } else if (score >= 55) {
      grade = 'C';
      premium = 0.007;
    } else {
      grade = 'D';
      premium = 0.012;
    }

    return RiskAssessment(
      score: score,
      grade: grade,
      monthlyPremium: premium,
      factors: [
        '${Fmt.percent(buyer.onTimeRate, digits: 0)} of invoices paid on time',
        'Pays ${buyer.avgDaysLate.toStringAsFixed(1)} days late on average',
        '${buyer.invoicesPaid} invoices paid through InvoiceFlow',
        '${buyer.yearsTrading} years trading history',
      ],
    );
  }

  /// Quotes from every partner that can fund the invoice, best payout first.
  List<FinancingOffer> offersFor({
    required Invoice invoice,
    required BuyerProfile buyer,
    required List<FundingPartner> partners,
    DateTime? now,
  }) {
    final risk = assessBuyer(buyer);
    final days = invoice.daysToDue(now).clamp(7, 180);
    final offers = <FinancingOffer>[];
    for (final partner in partners) {
      if (invoice.amount > partner.maxInvoiceAmount) continue;
      final rate = math.max(minFeeRate, (partner.monthlyBaseRate + risk.monthlyPremium) * days / 30);
      final fee = (invoice.amount * rate).roundToDouble();
      offers.add(FinancingOffer(
        partner: partner,
        invoice: invoice,
        feeRate: rate,
        feeAmount: fee,
        payoutAmount: invoice.amount - fee,
        riskGrade: risk.grade,
      ));
    }
    offers.sort((a, b) => b.payoutAmount.compareTo(a.payoutAmount));
    return offers;
  }

  /// Dynamic discounting: the buyer pays early from its own cash in exchange
  /// for a discount based on an annual rate and the number of days paid early.
  DiscountQuote dynamicDiscount({required Invoice invoice, required double annualRate, DateTime? now}) {
    final daysEarly = math.max(0, invoice.daysToDue(now));
    final discount = (invoice.amount * annualRate * daysEarly / 365).roundToDouble();
    return DiscountQuote(invoice: invoice, annualRate: annualRate, daysEarly: daysEarly, discount: discount);
  }
}
