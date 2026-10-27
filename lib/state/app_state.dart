import 'package:flutter/widgets.dart';

import '../core/formatters.dart';
import '../data/invoice_flow_repository.dart';
import '../data/mock_repository.dart';
import '../models/models.dart';
import '../services/fraud_checker.dart';
import '../services/pricing_engine.dart';
import '../services/reconciliation_service.dart';

/// Main tab indexes in [HomeShell].
abstract final class AppTab {
  static const home = 0;
  static const invoices = 1;
  static const financing = 2;
  static const analytics = 3;
  static const more = 4;
}

/// Holds the signed-in user and all loaded data. Screens read it through
/// [AppScope] and call its methods; it talks to the [InvoiceFlowRepository].
class AppState extends ChangeNotifier {
  AppState({InvoiceFlowRepository? repository}) : repository = repository ?? MockInvoiceFlowRepository();

  final InvoiceFlowRepository repository;
  final pricing = const PricingEngine();
  final fraudChecker = const FraudChecker();
  final reconciler = const ReconciliationService();

  AppUser? user;
  bool busy = false;

  List<Invoice> _invoices = [];
  List<Supplier> suppliers = [];
  List<FundingPartner> partners = [];
  List<BuyerProfile> buyerProfiles = [];
  List<FinancingRecord> _financings = [];
  List<ReconciliationEntry> _reconciliations = [];
  List<NotificationItem> notifications = [];
  WorkspaceSettings? settings;

  // Navigation state shared between tabs.
  int tabIndex = AppTab.home;
  String invoiceQuery = '';
  InvoiceStatus? invoiceFilter;
  String? financingInvoiceId;

  UserRole get role => user!.role;

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  Future<void> signIn({required String email, required String password, required UserRole role}) async {
    busy = true;
    notifyListeners();
    try {
      final signedIn = await repository.signIn(email: email, password: password, role: role);
      await _loadAll();
      tabIndex = AppTab.home;
      invoiceQuery = '';
      invoiceFilter = null;
      financingInvoiceId = null;
      user = signedIn;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void signOut() {
    user = null;
    tabIndex = AppTab.home;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadAll();
    notifyListeners();
  }

  Future<void> _loadAll() async {
    _invoices = await repository.fetchInvoices();
    suppliers = await repository.fetchSuppliers();
    partners = await repository.fetchFundingPartners();
    buyerProfiles = await repository.fetchBuyerProfiles();
    _financings = await repository.fetchFinancingRecords();
    _reconciliations = await repository.fetchReconciliations();
    settings = await repository.fetchSettings();
    notifications = await repository.fetchNotifications();
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void setTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  void showInvoices({String query = '', InvoiceStatus? filter}) {
    invoiceQuery = query;
    invoiceFilter = filter;
    tabIndex = AppTab.invoices;
    notifyListeners();
  }

  void setInvoiceQuery(String query) {
    invoiceQuery = query;
    notifyListeners();
  }

  void setInvoiceFilter(InvoiceStatus? filter) {
    invoiceFilter = filter;
    notifyListeners();
  }

  void openFinancingFor(String invoiceId) {
    financingInvoiceId = invoiceId;
    tabIndex = AppTab.financing;
    notifyListeners();
  }

  void selectFinancingInvoice(String? invoiceId) {
    financingInvoiceId = invoiceId;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Role-scoped data
  // ---------------------------------------------------------------------------

  /// Invoices the signed-in user is allowed to see, newest activity first.
  List<Invoice> get invoices {
    final u = user;
    if (u == null) return const [];
    final visible = switch (u.role) {
      UserRole.buyer => _invoices.where((i) => i.buyerId == u.organizationId),
      UserRole.supplier => _invoices.where((i) => i.supplierId == u.organizationId),
      UserRole.lender => _invoices.where((i) =>
          i.status == InvoiceStatus.approved ||
          ((i.status == InvoiceStatus.financed || i.status == InvoiceStatus.paid) &&
              financingFor(i)?.funderId == u.organizationId)),
    };
    return visible.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<FinancingRecord> get financings {
    final u = user;
    if (u == null) return const [];
    final visible = switch (u.role) {
      UserRole.buyer => _financings.where((r) => invoiceById(r.invoiceId)?.buyerId == u.organizationId),
      UserRole.supplier => _financings.where((r) => r.supplierId == u.organizationId),
      UserRole.lender => _financings.where((r) => r.funderId == u.organizationId),
    };
    return visible.toList()..sort((a, b) => b.fundedAt.compareTo(a.fundedAt));
  }

  List<ReconciliationEntry> get reconciliations {
    final ids = financings.map((r) => r.id).toSet();
    return _reconciliations.where((e) => ids.contains(e.financingId)).toList()
      ..sort((a, b) => b.settledAt.compareTo(a.settledAt));
  }

  List<Invoice> get approvedInvoices => invoices.where((i) => i.status == InvoiceStatus.approved).toList();

  int get unreadNotifications => notifications.where((n) => !n.read).length;

  Invoice? invoiceById(String id) {
    for (final i in _invoices) {
      if (i.id == id) return i;
    }
    return null;
  }

  Supplier? supplierById(String id) {
    for (final s in suppliers) {
      if (s.id == id) return s;
    }
    return null;
  }

  FinancingRecord? financingFor(Invoice invoice) {
    for (final r in _financings) {
      if (r.invoiceId == invoice.id) return r;
    }
    return null;
  }

  List<Invoice> invoicesForSupplier(String supplierId) => _invoices.where((i) => i.supplierId == supplierId).toList();

  BuyerProfile buyerFor(Invoice invoice) =>
      buyerProfiles.firstWhere((b) => b.id == invoice.buyerId, orElse: () => buyerProfiles.first);

  RiskAssessment riskFor(Invoice invoice) => pricing.assessBuyer(buyerFor(invoice));

  List<FinancingOffer> offersFor(Invoice invoice) =>
      pricing.offersFor(invoice: invoice, buyer: buyerFor(invoice), partners: partners);

  /// Total cash a supplier could unlock today from its approved invoices.
  double get unlockableCash => approvedInvoices.fold<double>(0, (sum, i) {
        final offers = offersFor(i);
        return sum + (offers.isEmpty ? 0.0 : offers.first.payoutAmount);
      });

  // ---------------------------------------------------------------------------
  // AP workflow
  // ---------------------------------------------------------------------------

  Future<void> approveInvoice(Invoice invoice) async {
    await _saveInvoice(invoice.copyWith(status: InvoiceStatus.approved, updatedAt: DateTime.now()));
    _notify('Invoice approved', '${invoice.number} is now eligible for early payment.');
    _audit('Approved ${invoice.number}');
  }

  Future<void> rejectInvoice(Invoice invoice, String reason) async {
    await _saveInvoice(invoice.copyWith(
      status: InvoiceStatus.rejected,
      updatedAt: DateTime.now(),
      rejectionReason: reason.isEmpty ? 'Rejected by buyer' : reason,
    ));
    _audit('Rejected ${invoice.number}');
  }

  /// Runs fraud and duplicate checks on a new invoice before it is submitted.
  FraudCheckResult checkInvoice(Invoice candidate) =>
      fraudChecker.check(candidate: candidate, existing: _invoices, supplier: supplierById(candidate.supplierId));

  Future<Invoice> submitInvoice(Invoice candidate) async {
    final result = checkInvoice(candidate);
    if (result.blocking.isNotEmpty) throw StateError(result.blocking.first);
    final invoice = candidate.copyWith(fraudFlags: result.warnings);
    await _saveInvoice(invoice);
    _notify('Invoice submitted', '${invoice.number} was sent to ${invoice.buyerName} for approval.');
    return invoice;
  }

  /// Builds an empty invoice for the signed-in supplier.
  Invoice draftInvoice({
    required String number,
    required double amount,
    required DateTime issueDate,
    required DateTime dueDate,
    required String poNumber,
    required String description,
    required List<InvoiceDocument> documents,
  }) {
    final u = user!;
    final buyer = buyerProfiles.first;
    return Invoice(
      id: _newId('i'),
      number: number.trim(),
      supplierId: u.organizationId,
      supplierName: u.organizationName,
      buyerId: buyer.id,
      buyerName: buyer.name,
      amount: amount,
      issueDate: issueDate,
      dueDate: dueDate,
      status: InvoiceStatus.pendingApproval,
      updatedAt: DateTime.now(),
      poNumber: poNumber,
      description: description,
      documents: documents,
    );
  }

  // ---------------------------------------------------------------------------
  // Financing
  // ---------------------------------------------------------------------------

  /// Instant early-payment financing through a funding partner.
  Future<FinancingRecord> acceptOffer(FinancingOffer offer) async {
    final invoice = offer.invoice;
    final record = FinancingRecord(
      id: _newId('f'),
      invoiceId: invoice.id,
      invoiceNumber: invoice.number,
      supplierId: invoice.supplierId,
      supplierName: invoice.supplierName,
      funderId: offer.partner.id,
      funderName: offer.partner.name,
      type: FinancingType.partner,
      invoiceAmount: invoice.amount,
      feeAmount: offer.feeAmount,
      payoutAmount: offer.payoutAmount,
      payoutHours: offer.partner.payoutHours,
      fundedAt: DateTime.now(),
      status: FinancingStatus.funded,
    );
    _financings = [..._financings, await repository.saveFinancingRecord(record)];
    await _saveInvoice(invoice.copyWith(status: InvoiceStatus.financed, updatedAt: DateTime.now()));
    if (financingInvoiceId == invoice.id) financingInvoiceId = null;
    _notify('Financing funded', '${offer.partner.name} will pay ${Fmt.money(offer.payoutAmount)} for ${invoice.number}.');
    return record;
  }

  /// Dynamic discounting: the buyer pays the supplier early from its own cash.
  Future<FinancingRecord> payEarly(DiscountQuote quote) async {
    final invoice = quote.invoice;
    final now = DateTime.now();
    final record = FinancingRecord(
      id: _newId('f'),
      invoiceId: invoice.id,
      invoiceNumber: invoice.number,
      supplierId: invoice.supplierId,
      supplierName: invoice.supplierName,
      funderId: invoice.buyerId,
      funderName: invoice.buyerName,
      type: FinancingType.dynamicDiscount,
      invoiceAmount: invoice.amount,
      feeAmount: quote.discount,
      payoutAmount: quote.supplierReceives,
      payoutHours: 0,
      fundedAt: now,
      status: FinancingStatus.settled,
      settledAt: now,
    );
    _financings = [..._financings, await repository.saveFinancingRecord(record)];
    final entry = ReconciliationEntry(
      id: _newId('r'),
      financingId: record.id,
      invoiceNumber: invoice.number,
      counterparty: invoice.buyerName,
      expectedAmount: quote.supplierReceives,
      receivedAmount: quote.supplierReceives,
      settledAt: now,
      matched: true,
      note: 'Auto-matched: early payment equals discounted amount',
    );
    _reconciliations = [..._reconciliations, await repository.saveReconciliation(entry)];
    await _saveInvoice(invoice.copyWith(status: InvoiceStatus.paid, updatedAt: now));
    if (financingInvoiceId == invoice.id) financingInvoiceId = null;
    _audit('Paid ${invoice.number} early with ${Fmt.money(quote.discount)} discount');
    return record;
  }

  /// Settlement at maturity + automated reconciliation.
  Future<ReconciliationEntry> settle(FinancingRecord record, {double? amountReceived}) async {
    final now = DateTime.now();
    final settled = await repository.saveFinancingRecord(record.copyWith(status: FinancingStatus.settled, settledAt: now));
    _financings = [for (final r in _financings) r.id == record.id ? settled : r];
    final entry = reconciler.reconcile(
      id: _newId('r'),
      record: record,
      amountReceived: amountReceived ?? record.invoiceAmount,
      settledAt: now,
    );
    _reconciliations = [..._reconciliations, await repository.saveReconciliation(entry)];
    final invoice = invoiceById(record.invoiceId);
    if (invoice != null) await _saveInvoice(invoice.copyWith(status: InvoiceStatus.paid, updatedAt: now));
    _notify(entry.matched ? 'Settlement reconciled' : 'Reconciliation exception', '${record.invoiceNumber}: ${entry.note}');
    return entry;
  }

  Future<void> resolveReconciliation(ReconciliationEntry entry) async {
    final resolved = await repository.saveReconciliation(
        entry.copyWith(matched: true, note: 'Resolved manually by ${user?.name ?? 'user'}'));
    _reconciliations = [for (final e in _reconciliations) e.id == entry.id ? resolved : e];
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Compliance (KYC / AML)
  // ---------------------------------------------------------------------------

  Future<void> setKycStatus(Supplier supplier, KycStatus status) async {
    final updated = await repository.saveSupplier(supplier.copyWith(kycStatus: status));
    suppliers = [for (final s in suppliers) s.id == supplier.id ? updated : s];
    _audit('Set KYC of ${supplier.name} to ${status.label}');
  }

  /// Simulated AML screening run. Returns the number of open alerts.
  Future<int> runAmlScreening() async {
    final current = settings;
    if (current != null) {
      await _saveSettings(WorkspaceSettings(
        roles: current.roles,
        members: current.members,
        integrations: current.integrations,
        notificationPrefs: current.notificationPrefs,
        auditLog: current.auditLog,
        compliance: current.compliance.copyWith(lastAmlScreening: DateTime.now()),
      ));
    }
    _audit('Ran AML screening on ${suppliers.length} suppliers');
    return suppliers.where((s) => !s.amlCleared).length;
  }

  Future<void> clearAmlAlert(Supplier supplier) async {
    final updated = await repository.saveSupplier(supplier.copyWith(amlCleared: true));
    suppliers = [for (final s in suppliers) s.id == supplier.id ? updated : s];
    _audit('Cleared AML alert for ${supplier.name}');
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  Future<void> saveRole(AccessRole role) async {
    final s = settings!;
    final exists = s.roles.any((r) => r.id == role.id);
    final roles = exists ? [for (final r in s.roles) r.id == role.id ? role : r] : [...s.roles, role];
    await _updateSettings(roles: roles);
    _audit('${exists ? 'Updated' : 'Created'} role ${role.name}');
  }

  Future<void> deleteRole(AccessRole role) async {
    await _updateSettings(roles: settings!.roles.where((r) => r.id != role.id).toList());
    _audit('Deleted role ${role.name}');
  }

  Future<void> inviteMember(TeamMember member) async {
    await _updateSettings(members: [...settings!.members, member]);
    _audit('Invited ${member.email}');
  }

  Future<void> toggleIntegration(Integration integration) async {
    final updated = integration.copyWith(connected: !integration.connected);
    await _updateSettings(integrations: [for (final i in settings!.integrations) i.id == integration.id ? updated : i]);
    _audit('${updated.connected ? 'Connected' : 'Disconnected'} ${integration.name}');
  }

  Future<void> setNotificationPref(String key, bool value) =>
      _updateSettings(notificationPrefs: {...settings!.notificationPrefs, key: value});

  void markNotificationsRead() {
    if (unreadNotifications == 0) return;
    notifications = [for (final n in notifications) n.markRead()];
    notifyListeners();
  }

  String newId(String prefix) => _newId(prefix);

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _saveInvoice(Invoice invoice) async {
    final saved = await repository.saveInvoice(invoice);
    final exists = _invoices.any((i) => i.id == saved.id);
    _invoices = exists ? [for (final i in _invoices) i.id == saved.id ? saved : i] : [..._invoices, saved];
    notifyListeners();
  }

  Future<void> _updateSettings({
    List<AccessRole>? roles,
    List<TeamMember>? members,
    List<Integration>? integrations,
    Map<String, bool>? notificationPrefs,
  }) {
    final s = settings!;
    return _saveSettings(WorkspaceSettings(
      roles: roles ?? s.roles,
      members: members ?? s.members,
      integrations: integrations ?? s.integrations,
      notificationPrefs: notificationPrefs ?? s.notificationPrefs,
      auditLog: s.auditLog,
      compliance: s.compliance,
    ));
  }

  Future<void> _saveSettings(WorkspaceSettings value) async {
    settings = value;
    notifyListeners();
    await repository.saveSettings(value);
  }

  void _audit(String action) {
    final s = settings;
    if (s == null) return;
    settings = WorkspaceSettings(
      roles: s.roles,
      members: s.members,
      integrations: s.integrations,
      notificationPrefs: s.notificationPrefs,
      auditLog: [AuditEvent(action: action, actor: user?.name ?? 'System', time: DateTime.now()), ...s.auditLog],
      compliance: s.compliance,
    );
    notifyListeners();
  }

  void _notify(String title, String body) {
    notifications = [NotificationItem(title: title, body: body, time: DateTime.now()), ...notifications];
    notifyListeners();
  }

  int _idCounter = 0;
  String _newId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';
}

/// Makes [AppState] available to every widget below it.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Reads the state and rebuilds the caller when it changes.
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads the state without listening (use in callbacks and initState).
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
