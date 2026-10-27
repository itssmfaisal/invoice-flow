import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  // Uses MockInvoiceFlowRepository (dummy data) by default.
  // When the backend is ready: runApp(InvoiceFlowApp(repository: ApiInvoiceFlowRepository(...)));
  runApp(const InvoiceFlowApp());
}
