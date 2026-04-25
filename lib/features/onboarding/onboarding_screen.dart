import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/auth_gate.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = isFormallyLoggedIn(user);
    final email = user?.email ?? '';
    final showAdmin = isAdminUser(user);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('appName')),
        actions: [
          if (isLoggedIn) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Center(
                child: Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.t('logoutDone'))),
                );
              },
              child: Text(s.t('logoutAction')),
            ),
          ] else
            TextButton(
              onPressed: () => showLoginModal(context),
              child: Text(s.t('loginAction')),
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
              ActionChip(
                label: const Text('Español MX'),
                onPressed: () => widget.onLocaleChanged(const Locale('es', 'MX')),
              ),
              ActionChip(
                label: const Text('English'),
                onPressed: () => widget.onLocaleChanged(const Locale('en')),
              ),
              if (showAdmin)
                ActionChip(
                  label: const Text('繁體中文'),
                  onPressed: () => widget.onLocaleChanged(const Locale('zh', 'TW')),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _HomeActionCard(
            icon: Icons.add_circle_outline,
            title: s.t('customer'),
            subtitle: s.t('customerSubtitle'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerShell(),
              ),
            ),
          ),
          _HomeActionCard(
            icon: Icons.handshake_outlined,
            title: s.t('runner'),
            subtitle: s.t('runnerSubtitle'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RunnerShell(),
              ),
            ),
          ),
          if (showAdmin)
            _HomeActionCard(
              icon: Icons.admin_panel_settings_outlined,
              title: s.t('adminPanelInternal'),
              subtitle: s.t('adminSubtitle'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminDashboardScreen(onLocaleChanged: widget.onLocaleChanged),
                ),
              ),
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
