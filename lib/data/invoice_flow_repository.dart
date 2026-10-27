import '../models/models.dart';

/// Everything the app needs from the backend.
///
/// The app currently uses [MockInvoiceFlowRepository]. To connect the real
/// API, write an `ApiInvoiceFlowRepository` that implements this interface
/// (e.g. with `package:http`) and pass it to `InvoiceFlowApp` in `main.dart`.
abstract interface class InvoiceFlowRepository {
  Future<AppUser> signIn({required String email, required String password, required UserRole role});

  Future<List<Invoice>> fetchInvoices();
  Future<Invoice> saveInvoice(Invoice invoice);

  Future<List<Supplier>> fetchSuppliers();
  Future<Supplier> saveSupplier(Supplier supplier);

  Future<List<BuyerProfile>> fetchBuyerProfiles();
  Future<List<FundingPartner>> fetchFundingPartners();

  Future<List<FinancingRecord>> fetchFinancingRecords();
  Future<FinancingRecord> saveFinancingRecord(FinancingRecord record);

  Future<List<ReconciliationEntry>> fetchReconciliations();
  Future<ReconciliationEntry> saveReconciliation(ReconciliationEntry entry);

  Future<WorkspaceSettings> fetchSettings();
  Future<void> saveSettings(WorkspaceSettings settings);

  Future<List<NotificationItem>> fetchNotifications();
}
