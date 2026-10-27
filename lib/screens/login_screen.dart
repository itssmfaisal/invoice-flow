import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _demoEmails = {
    UserRole.buyer: 'alex@abcmanufacturing.com',
    UserRole.supplier: 'sam@techsolutions.com',
    UserRole.lender: 'lena@fastfund.com',
  };

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.buyer;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _pickRole(UserRole role) {
    setState(() {
      _role = role;
      _email.text = _demoEmails[role]!;
      _password.text = 'demo1234';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    try {
      await AppScope.read(context).signIn(email: _email.text.trim(), password: _password.text, role: _role);
    } catch (e) {
      if (mounted) showSnack(context, 'Sign in failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = AppScope.of(context).busy;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 36)),
                    const SizedBox(height: 18),
                    const Text('Welcome Back',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Sign in to continue',
                        textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 28),
                    const _Label('Email'),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(hintText: 'you@company.com', prefixIcon: Icon(Icons.mail_outline)),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 14),
                    const _Label('Password'),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 4) ? 'Password must be at least 4 characters' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => showSnack(context, 'Password reset will work once the API is connected'),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FilledButton(
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text('Login as ${_role.label}'),
                    ),
                    const SizedBox(height: 26),
                    const Row(children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or continue with', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ),
                      Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final role in UserRole.values) ...[
                          if (role != UserRole.values.first) const SizedBox(width: 10),
                          Expanded(
                            child: _RoleTile(role: role, selected: role == _role, onTap: () => _pickRole(role)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Demo mode: pick a role to fill in a demo account.\n${_role.label} · ${_role.description}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () => showSnack(context, 'Sign up will work once the API is connected'),
                          child: const Text('Sign up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      );
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.role, required this.selected, required this.onTap});

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.purple : AppColors.lavenderLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(children: [
            Icon(roleIcon(role), color: selected ? Colors.white : AppColors.purple),
            const SizedBox(height: 6),
            Text(role.label,
                style: TextStyle(fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.purpleDark)),
          ]),
        ),
      ),
    );
  }
}
