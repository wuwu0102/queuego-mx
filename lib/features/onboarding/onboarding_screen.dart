import 'package:flutter/material.dart';

import '../../core/constants/app_enums.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/services/auth_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../customer/customer_shell.dart';
import '../runner/runner_shell.dart';
import '../shared/terms_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  UserRole role = UserRole.customer;
  final emailController = TextEditingController(text: 'demo@queuego.mx');
  final auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('appName')),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
            child: Text(s.t('terms')),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.t('slogan'), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            Text(s.t('chooseLanguage')),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(label: const Text('繁中'), onPressed: () => widget.onLocaleChanged(const Locale('zh', 'TW'))),
                ActionChip(label: const Text('English'), onPressed: () => widget.onLocaleChanged(const Locale('en'))),
                ActionChip(label: const Text('Español MX'), onPressed: () => widget.onLocaleChanged(const Locale('es', 'MX'))),
              ],
            ),
            const SizedBox(height: 20),
            Text(s.t('chooseRole')),
            SegmentedButton<UserRole>(
              segments: [
                ButtonSegment(value: UserRole.customer, label: Text(s.t('customer'))),
                ButtonSegment(value: UserRole.runner, label: Text(s.t('runner'))),
                ButtonSegment(value: UserRole.admin, label: Text(s.t('admin'))),
              ],
              selected: {role},
              onSelectionChanged: (values) => setState(() => role = values.first),
            ),
            const SizedBox(height: 20),
            TextField(controller: emailController, decoration: InputDecoration(labelText: s.t('emailLogin'))),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () async {
                await auth.loginWithEmail(email: emailController.text, role: role);
                if (!mounted) return;
                final widget = switch (role) {
                  UserRole.customer => const CustomerShell(),
                  UserRole.runner => const RunnerShell(),
                  UserRole.admin => const AdminDashboardScreen(),
                };
                Navigator.push(context, MaterialPageRoute(builder: (_) => widget));
              },
              child: Text(s.t('mockLogin')),
            ),
            const SizedBox(height: 8),
            const Text('Firebase Auth ready point: replace mock action with signInWithEmailAndPassword.'),
          ],
        ),
      ),
    );
  }
}
