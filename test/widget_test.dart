import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_flow/main.dart';

void main() {
  testWidgets('shows the InvoiceFlow dashboard', (tester) async {
    await tester.pumpWidget(const InvoiceFlowApp());
    expect(find.text('InvoiceFlow'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Recent invoices'), findsOneWidget);
  });
}
