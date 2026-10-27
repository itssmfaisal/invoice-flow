import '../models/models.dart';
import 'invoice_flow_repository.dart';

/// In-memory backend with dummy data. Replace with a real API implementation.
class MockInvoiceFlowRepository implements InvoiceFlowRepository {
  MockInvoiceFlowRepository({this.latency = const Duration(milliseconds: 350), DateTime? now})
      : _now = now ?? DateTime.now() {
    _seed();
  }

  final Duration latency;
  final DateTime _now;

  final List<Invoice> _invoices = [];
  final List<Supplier> _suppliers = [];
  final List<FinancingRecord> _financings = [];
  final List<ReconciliationEntry> _reconciliations = [];
  late WorkspaceSettings _settings;

  static const buyerId = 'b1';
  static const buyerName = 'ABC Manufacturing';

  Future<T> _delay<T>(T value) => Future.delayed(latency, () => value);

  DateTime _days(int offset) => _now.add(Duration(days: offset));

  @override
  Future<AppUser> signIn({required String email, required String password, required UserRole role}) {
    if (email.trim().isEmpty || password.isEmpty) {
      return Future.error(Exception('Email and password are required'));
    }
    final user = switch (role) {
      UserRole.buyer => AppUser(
          id: 'u1', name: 'Alex Smith', email: email, role: role, organizationId: buyerId, organizationName: buyerName),
      UserRole.supplier => AppUser(
          id: 'u2',
          name: 'Sam Rahman',
          email: email,
          role: role,
          organizationId: 's1',
          organizationName: 'Tech Solutions Ltd.'),
      UserRole.lender => AppUser(
          id: 'u3', name: 'Lena Park', email: email, role: role, organizationId: 'p1', organizationName: 'FastFund Bank'),
    };
    return _delay(user);
  }

  @override
  Future<List<Invoice>> fetchInvoices() => _delay(List.of(_invoices));

  @override
  Future<Invoice> saveInvoice(Invoice invoice) {
    _upsert(_invoices, invoice, (i) => i.id == invoice.id);
    return _delay(invoice);
  }

  @override
  Future<List<Supplier>> fetchSuppliers() => _delay(List.of(_suppliers));

  @override
  Future<Supplier> saveSupplier(Supplier supplier) {
    _upsert(_suppliers, supplier, (s) => s.id == supplier.id);
    return _delay(supplier);
  }

  @override
  Future<List<BuyerProfile>> fetchBuyerProfiles() => _delay(const [
        BuyerProfile(
            id: buyerId, name: buyerName, onTimeRate: 0.86, avgDaysLate: 4.2, invoicesPaid: 184, yearsTrading: 12),
      ]);

  @override
  Future<List<FundingPartner>> fetchFundingPartners() => _delay(const [
        FundingPartner(
            id: 'p1', name: 'FastFund Bank', type: 'Bank', monthlyBaseRate: 0.015, payoutHours: 24, maxInvoiceAmount: 500000),
        FundingPartner(
            id: 'p2',
            name: 'BlueRiver Capital',
            type: 'Credit fund',
            monthlyBaseRate: 0.018,
            payoutHours: 24,
            maxInvoiceAmount: 1000000),
        FundingPartner(
            id: 'p3',
            name: 'QuickPay Finance',
            type: 'Fintech lender',
            monthlyBaseRate: 0.013,
            payoutHours: 48,
            maxInvoiceAmount: 100000),
      ]);

  @override
  Future<List<FinancingRecord>> fetchFinancingRecords() => _delay(List.of(_financings));

  @override
  Future<FinancingRecord> saveFinancingRecord(FinancingRecord record) {
    _upsert(_financings, record, (r) => r.id == record.id);
    return _delay(record);
  }

  @override
  Future<List<ReconciliationEntry>> fetchReconciliations() => _delay(List.of(_reconciliations));

  @override
  Future<ReconciliationEntry> saveReconciliation(ReconciliationEntry entry) {
    _upsert(_reconciliations, entry, (e) => e.id == entry.id);
    return _delay(entry);
  }

  @override
  Future<WorkspaceSettings> fetchSettings() => _delay(_settings);

  @override
  Future<void> saveSettings(WorkspaceSettings settings) {
    _settings = settings;
    return _delay(null);
  }

  @override
  Future<List<NotificationItem>> fetchNotifications() => _delay([
        NotificationItem(
            title: 'Invoice awaiting approval',
            body: 'INV-1009 from Global Retail Inc. needs your review.',
            time: _now.subtract(const Duration(minutes: 12))),
        NotificationItem(
            title: 'Duplicate invoice flagged',
            body: 'INV-1011 matches the amount of INV-1003 from CyberSolutions Ltd.',
            time: _now.subtract(const Duration(hours: 3))),
        NotificationItem(
            title: 'Financing funded',
            body: 'FastFund Bank paid \$117,300 for INV-1006.',
            time: _now.subtract(const Duration(days: 1))),
        NotificationItem(
            title: 'Reconciliation exception',
            body: 'INV-1007 settlement is \$50 short.',
            time: _now.subtract(const Duration(days: 10)),
            read: true),
      ]);

  void _upsert<T>(List<T> list, T item, bool Function(T) match) {
    final index = list.indexWhere(match);
    if (index == -1) {
      list.add(item);
    } else {
      list[index] = item;
    }
  }

  // ---------------------------------------------------------------------------
  // Dummy data
  // ---------------------------------------------------------------------------

  void _seed() {
    _suppliers.addAll([
      Supplier(id: 's1', name: 'Tech Solutions Ltd.', category: 'IT services', kycStatus: KycStatus.verified, amlCleared: true, joinedAt: _days(-700), contactEmail: 'finance@techsolutions.com'),
      Supplier(id: 's2', name: 'CyberSolutions Ltd.', category: 'Cyber security', kycStatus: KycStatus.verified, amlCleared: true, joinedAt: _days(-420), contactEmail: 'ar@cybersolutions.io'),
      Supplier(id: 's3', name: 'TechniqueSolutions Ltd.', category: 'Engineering', kycStatus: KycStatus.pending, amlCleared: true, joinedAt: _days(-20), contactEmail: 'billing@technique.co'),
      Supplier(id: 's4', name: 'Green Supplies Co.', category: 'Raw materials', kycStatus: KycStatus.verified, amlCleared: true, joinedAt: _days(-900), contactEmail: 'accounts@greensupplies.com'),
      Supplier(id: 's5', name: 'BuildWell Pvt. Ltd.', category: 'Construction', kycStatus: KycStatus.verified, amlCleared: true, joinedAt: _days(-560), contactEmail: 'finance@buildwell.com'),
      Supplier(id: 's6', name: 'Office Needs Inc.', category: 'Office supplies', kycStatus: KycStatus.verified, amlCleared: true, joinedAt: _days(-300), contactEmail: 'ar@officeneeds.com'),
      Supplier(id: 's7', name: 'Global Retail Inc.', category: 'Distribution', kycStatus: KycStatus.verified, amlCleared: false, joinedAt: _days(-150), contactEmail: 'pay@globalretail.com'),
    ]);

    Invoice inv(String id, String number, String supplierId, double amount, int issuedDaysAgo, int dueInDays,
        InvoiceStatus status, Duration updatedAgo,
        {List<String> flags = const [], String? rejection, String po = ''}) {
      final supplier = _suppliers.firstWhere((s) => s.id == supplierId);
      return Invoice(
        id: id,
        number: number,
        supplierId: supplierId,
        supplierName: supplier.name,
        buyerId: buyerId,
        buyerName: buyerName,
        amount: amount,
        issueDate: _days(-issuedDaysAgo),
        dueDate: _days(dueInDays),
        status: status,
        updatedAt: _now.subtract(updatedAgo),
        poNumber: po.isEmpty ? 'PO-${number.substring(4)}' : po,
        description: '${supplier.category} services',
        documents: [
          InvoiceDocument(name: 'invoice_${number.substring(4)}.pdf', sizeKb: 182),
          if (amount > 30000) InvoiceDocument(name: 'delivery_note_${number.substring(4)}.pdf', sizeKb: 96),
        ],
        fraudFlags: flags,
        rejectionReason: rejection,
      );
    }

    _invoices.addAll([
      inv('i1002', 'INV-1002', 's1', 25000, 3, 45, InvoiceStatus.approved, const Duration(minutes: 2)),
      inv('i1003', 'INV-1003', 's2', 20000, 4, 46, InvoiceStatus.pendingApproval, const Duration(days: 1)),
      inv('i1004', 'INV-1004', 's3', 50000, 15, 45, InvoiceStatus.pendingApproval, const Duration(days: 30),
          flags: ['Supplier KYC is pending review']),
      inv('i1005', 'INV-1005', 's4', 48500, 10, 60, InvoiceStatus.approved, const Duration(hours: 5)),
      inv('i1006', 'INV-1006', 's5', 120000, 25, 30, InvoiceStatus.financed, const Duration(days: 5)),
      inv('i1007', 'INV-1007', 's6', 8750, 70, -10, InvoiceStatus.paid, const Duration(days: 10)),
      inv('i1008', 'INV-1008', 's1', 32000, 20, 40, InvoiceStatus.financed, const Duration(days: 3)),
      inv('i1009', 'INV-1009', 's7', 64000, 2, 50, InvoiceStatus.pendingApproval, const Duration(minutes: 12),
          flags: ['Supplier has an open AML screening alert']),
      inv('i1010', 'INV-1010', 's1', 18400, 1, 55, InvoiceStatus.pendingApproval, const Duration(hours: 20)),
      inv('i1011', 'INV-1011', 's2', 20000, 1, 49, InvoiceStatus.pendingApproval, const Duration(hours: 3),
          flags: ['Possible duplicate: same amount as INV-1003 within 30 days']),
      inv('i1012', 'INV-1012', 's5', 76000, 60, -5, InvoiceStatus.paid, const Duration(days: 20)),
      inv('i1013', 'INV-1013', 's4', 15200, 40, 20, InvoiceStatus.rejected, const Duration(days: 38),
          rejection: 'Amount does not match purchase order'),
      inv('i1014', 'INV-1014', 's1', 41000, 95, -35, InvoiceStatus.paid, const Duration(days: 35)),
      inv('i1015', 'INV-1015', 's6', 22300, 6, 38, InvoiceStatus.approved, const Duration(hours: 9)),
      inv('i1016', 'INV-1016', 's4', 36800, 120, -60, InvoiceStatus.paid, const Duration(days: 60)),
      inv('i1017', 'INV-1017', 's1', 27500, 140, -80, InvoiceStatus.paid, const Duration(days: 80)),
    ]);

    FinancingRecord rec(String id, String invoiceId, String funderId, String funderName, FinancingType type, double fee,
        int hours, int fundedDaysAgo, {int? settledDaysAgo}) {
      final invoice = _invoices.firstWhere((i) => i.id == invoiceId);
      return FinancingRecord(
        id: id,
        invoiceId: invoiceId,
        invoiceNumber: invoice.number,
        supplierId: invoice.supplierId,
        supplierName: invoice.supplierName,
        funderId: funderId,
        funderName: funderName,
        type: type,
        invoiceAmount: invoice.amount,
        feeAmount: fee,
        payoutAmount: invoice.amount - fee,
        payoutHours: hours,
        fundedAt: _days(-fundedDaysAgo),
        status: settledDaysAgo == null ? FinancingStatus.funded : FinancingStatus.settled,
        settledAt: settledDaysAgo == null ? null : _days(-settledDaysAgo),
      );
    }

    _financings.addAll([
      rec('f1', 'i1006', 'p1', 'FastFund Bank', FinancingType.partner, 2700, 24, 5),
      rec('f2', 'i1008', 'p3', 'QuickPay Finance', FinancingType.partner, 640, 48, 3),
      rec('f3', 'i1007', 'p2', 'BlueRiver Capital', FinancingType.partner, 260, 24, 55, settledDaysAgo: 10),
      rec('f4', 'i1012', buyerId, buyerName, FinancingType.dynamicDiscount, 1000, 0, 40, settledDaysAgo: 40),
      rec('f5', 'i1014', 'p1', 'FastFund Bank', FinancingType.partner, 1150, 24, 80, settledDaysAgo: 35),
      rec('f6', 'i1016', 'p2', 'BlueRiver Capital', FinancingType.partner, 990, 24, 110, settledDaysAgo: 60),
    ]);

    _reconciliations.addAll([
      ReconciliationEntry(id: 'r1', financingId: 'f3', invoiceNumber: 'INV-1007', counterparty: 'BlueRiver Capital', expectedAmount: 8750, receivedAmount: 8700, settledAt: _days(-10), matched: false, note: 'Short payment of \$50, sent for review'),
      ReconciliationEntry(id: 'r2', financingId: 'f4', invoiceNumber: 'INV-1012', counterparty: buyerName, expectedAmount: 75000, receivedAmount: 75000, settledAt: _days(-40), matched: true, note: 'Auto-matched: early payment equals discounted amount'),
      ReconciliationEntry(id: 'r3', financingId: 'f5', invoiceNumber: 'INV-1014', counterparty: 'FastFund Bank', expectedAmount: 41000, receivedAmount: 41000, settledAt: _days(-35), matched: true, note: 'Auto-matched: payment equals invoice amount'),
      ReconciliationEntry(id: 'r4', financingId: 'f6', invoiceNumber: 'INV-1016', counterparty: 'BlueRiver Capital', expectedAmount: 36800, receivedAmount: 36800, settledAt: _days(-60), matched: true, note: 'Auto-matched: payment equals invoice amount'),
    ]);

    _settings = WorkspaceSettings(
      roles: const [
        AccessRole(id: 'role1', name: 'Buyer Admin', description: 'Full access', permissions: 24, users: 5),
        AccessRole(id: 'role2', name: 'Buyer User', description: 'View', permissions: 12, users: 18),
        AccessRole(id: 'role3', name: 'Supplier User', description: 'Manage', permissions: 10, users: 265),
        AccessRole(id: 'role4', name: 'Lender', description: 'View', permissions: 6, users: 12),
      ],
      members: const [
        TeamMember(name: 'Alex Smith', email: 'alex@abcmanufacturing.com', roleName: 'Buyer Admin'),
        TeamMember(name: 'Priya Nair', email: 'priya@abcmanufacturing.com', roleName: 'Buyer Admin'),
        TeamMember(name: 'Omar Haddad', email: 'omar@abcmanufacturing.com', roleName: 'Buyer User'),
        TeamMember(name: 'Grace Lee', email: 'grace@abcmanufacturing.com', roleName: 'Buyer User'),
        TeamMember(name: 'Tom Becker', email: 'tom@abcmanufacturing.com', roleName: 'Buyer User', active: false),
      ],
      integrations: const [
        Integration(id: 'sap', name: 'SAP Ariba', description: 'Procurement: sync POs and approved invoices', connected: true),
        Integration(id: 'coupa', name: 'Coupa', description: 'Procurement & AP automation', connected: false),
        Integration(id: 'netsuite', name: 'Oracle NetSuite', description: 'ERP: AP ledger and payment runs', connected: true),
        Integration(id: 'qb', name: 'QuickBooks', description: 'Supplier accounting sync', connected: false),
        Integration(id: 'bank', name: 'Bank feed (Open Banking)', description: 'Settlement data for auto-reconciliation', connected: true),
      ],
      notificationPrefs: const {
        'New invoice submitted': true,
        'Invoice approved / rejected': true,
        'Financing funded': true,
        'Settlement & reconciliation': true,
        'Fraud & duplicate alerts': true,
        'Weekly liquidity summary': false,
      },
      auditLog: [
        AuditEvent(action: 'Approved INV-1002', actor: 'Alex Smith', time: _now.subtract(const Duration(minutes: 2))),
        AuditEvent(action: 'Changed role permissions: Buyer User', actor: 'Priya Nair', time: _days(-2)),
        AuditEvent(action: 'Connected Oracle NetSuite', actor: 'Alex Smith', time: _days(-9)),
        AuditEvent(action: 'Rejected INV-1013', actor: 'Omar Haddad', time: _days(-38)),
      ],
      compliance: ComplianceInfo(
        licenseType: 'Factoring & receivables finance licence',
        licenseNumber: 'FRL-2024-00871',
        regulator: 'Financial Conduct Authority',
        licenseValidUntil: DateTime(_now.year + 2, 3, 31),
        lastAmlScreening: _days(-1),
      ),
    );
  }
}
