import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/services/auth_gate.dart';

class LoginModal extends StatefulWidget {
  const LoginModal({super.key});

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await _runAuthAction((email, password) {
      return FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }, successMessage: null, notifyLoginSuccess: true);
  }

  Future<void> _register() async {
    await _runAuthAction((email, password) {
      return FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }, successMessage: AppStrings.of(context).t('authAccountCreated'));
  }

  Future<void> _runAuthAction(
    Future<UserCredential> Function(String email, String password) action,
    {String? successMessage, bool notifyLoginSuccess = false}
  ) async {
    final s = AppStrings.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('fillAllFields'))),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final credential = await action(email, password);
      if (!mounted) return;
      if (notifyLoginSuccess) {
        final user = credential.user;
        final loginMessage = isAdminUser(user)
            ? '管理員登入成功 / Admin login successful / Administrador conectado'
            : s.t('loginSuccess');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loginMessage)),
        );
      }
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final code = error.code;
      final message = switch (code) {
        'wrong-password' || 'invalid-credential' => s.t('authWrongPassword'),
        'user-not-found' => s.t('authUserNotFound'),
        _ => s.t('authUnknownError'),
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.t('progressiveLoginTitle'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(s.t('progressiveLoginSubtitle')),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofocus: true,
                enabled: !_loading,
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                decoration: InputDecoration(labelText: s.t('emailLabel')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: !_showPassword,
                enabled: !_loading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _loading ? null : _login(),
                decoration: InputDecoration(
                  labelText: s.t('passwordLabel'),
                  suffixIcon: IconButton(
                    onPressed: _loading ? null : () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _login,
                  child: Text(_loading ? s.t('saving') : s.t('loginCta')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _loading ? null : _register,
                  child: Text(s.t('registerCta')),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Text(s.t('continueBrowsing'))),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> showLoginModal(BuildContext context) async {
  final loggedIn = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const LoginModal(),
  );
  return loggedIn ?? false;
}
