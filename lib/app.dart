import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/invoice_flow_repository.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'state/app_state.dart';

class InvoiceFlowApp extends StatefulWidget {
  const InvoiceFlowApp({super.key, this.repository});

  /// Backend implementation. Defaults to dummy data.
  final InvoiceFlowRepository? repository;

  @override
  State<InvoiceFlowApp> createState() => _InvoiceFlowAppState();
}

class _InvoiceFlowAppState extends State<InvoiceFlowApp> {
  late final AppState _state = AppState(repository: widget.repository);

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'InvoiceFlow',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final signedIn = AppScope.of(context).user != null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: signedIn ? const HomeShell(key: ValueKey('shell')) : const LoginScreen(key: ValueKey('login')),
    );
  }
}
