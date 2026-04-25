import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await _runAuthAction((email, password) {
      return FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> _register() async {
    await _runAuthAction((email, password) {
      return FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> _runAuthAction(
    Future<UserCredential> Function(String email, String password) action,
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
      await action(email, password);
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.t('authErrorPrefix')}: ${error.message ?? error.code}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('loginTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: s.t('emailLabel')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: s.t('passwordLabel')),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _login,
            child: Text(s.t('loginCta')),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _loading ? null : _register,
            child: Text(s.t('registerCta')),
          ),
        ],
      ),
    );
  }
}
