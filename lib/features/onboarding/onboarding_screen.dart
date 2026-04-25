import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/i18n/app_strings.dart';
import '../admin/admin_dashboard_screen.dart';
import '../customer/customer_shell.dart';
import '../runner/runner_shell.dart';
import 'auth_screen.dart';
import '../shared/terms_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('appName')),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            ),
            child: Text(s.t('loginAction')),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await FirebaseAuth.instance.signInAnonymously();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.t('logoutDone'))),
              );
            },
            child: Text(s.t('logoutAction')),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
            child: Text(s.t('terms')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return _AuthStatusCard(user: user);
            },
          ),
          const SizedBox(height: 16),
          Text(
            s.t('sloganMvp'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(s.t('chooseLanguage')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(label: const Text('Español MX'), onPressed: () => widget.onLocaleChanged(const Locale('es', 'MX'))),
              ActionChip(label: const Text('English'), onPressed: () => widget.onLocaleChanged(const Locale('en'))),
              ActionChip(label: const Text('繁中'), onPressed: () => widget.onLocaleChanged(const Locale('zh', 'TW'))),
            ],
          ),
          const SizedBox(height: 20),
          _HomeActionCard(
            icon: Icons.add_circle_outline,
            title: s.t('customer'),
            subtitle: s.t('customerSubtitle'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerShell())),
          ),
          _HomeActionCard(
            icon: Icons.handshake_outlined,
            title: s.t('runner'),
            subtitle: s.t('runnerSubtitle'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RunnerShell())),
          ),
          _HomeActionCard(
            icon: Icons.admin_panel_settings_outlined,
            title: s.t('admin'),
            subtitle: s.t('adminSubtitle'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
          ),
          const SizedBox(height: 8),
          Text(
            s.t('firebaseMockNotice'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AuthStatusCard extends StatelessWidget {
  const _AuthStatusCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final uid = user?.uid ?? '';
    final uidTail = uid.length <= 6 ? uid : uid.substring(uid.length - 6);
    final isAnonymous = user == null || user.isAnonymous;
    final isEmail = !isAnonymous &&
        user!.providerData.any((provider) => provider.providerId == 'password');
    final method = isAnonymous ? s.t('authMethodAnonymous') : (isEmail ? s.t('authMethodEmail') : s.t('authMethodUnknown'));
    final userLine = isAnonymous
        ? s.t('currentAnonymousUser').replaceAll('{uid}', uidTail)
        : s.t('currentUserEmail').replaceAll('{email}', user?.email ?? '-');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.t('loginStatusTitle'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(userLine),
            Text('${s.t('loginMethod')}: $method'),
          ],
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
