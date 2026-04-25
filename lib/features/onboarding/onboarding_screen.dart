import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/auth_gate.dart';
import '../../core/services/user_profile_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../customer/customer_shell.dart';
import '../runner/runner_shell.dart';
import '../shared/task_history_screen.dart';
import '../shared/terms_screen.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _rolePromptedUid;
  String? _adminWelcomedUid;
  bool _attemptedAnonymousSignIn = false;

  @override
  void initState() {
    super.initState();
    _ensureAnonymousSession();
  }

  Future<void> _ensureAnonymousSession() async {
    if (_attemptedAnonymousSignIn) return;
    _attemptedAnonymousSignIn = true;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) return;
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException {
      // Keep the app usable even if anonymous auth is disabled.
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final currentUser = snapshot.data ?? FirebaseAuth.instance.currentUser;
        _ensureUserProfileFlow(currentUser);
        return _buildScaffold(context, currentUser);
      },
    );
  }

  Future<void> _ensureUserProfileFlow(User? user) async {
    if (!isFormallyLoggedIn(user)) return;
    final created = await UserProfileService.instance.ensureProfile(user);
    final uid = user?.uid ?? '';
    if (!mounted || uid.isEmpty) return;
    if (isAdminUser(user) && _adminWelcomedUid != uid) {
      _adminWelcomedUid = uid;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '管理員登入成功 / Admin login successful / Administrador conectado',
          ),
        ),
      );
    }
    if (!created || _rolePromptedUid == uid || isAdminUser(user)) {
      _rolePromptedUid = uid;
      return;
    }
    _rolePromptedUid = uid;
    final role = await _showRoleDialog(context);
    if (role == null) return;
    await UserProfileService.instance.updateRole(uid: uid, role: role);
  }

  Future<String?> _showRoleDialog(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = switch (languageCode) {
      'en' => 'What do you want to do in QueueGo?',
      'zh' when isAdminUser(FirebaseAuth.instance.currentUser) => '你想在 QueueGo 做什麼？',
      _ => '¿Qué quieres hacer en QueueGo?',
    };
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'customer'), child: const Text('Publicar tareas / 發任務 / Post tasks')),
          TextButton(onPressed: () => Navigator.pop(context, 'runner'), child: const Text('Tomar tareas / 接任務 / Take tasks')),
          FilledButton(onPressed: () => Navigator.pop(context, 'both'), child: const Text('Ambas / 兩者都要 / Both')),
        ],
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, User? currentUser) {
    final s = AppStrings.of(context);
    final isLoggedIn = isFormallyLoggedIn(currentUser);
    final email = currentUser?.email ?? '';
    final showAdmin = isAdminUser(currentUser);
    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: Text(s.t('appName')),
          actions: [
            TextButton(
              onPressed: () => showLoginModal(context),
              child: Text(s.t('loginAction')),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsScreen()),
              ),
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
              ],
            ),
            const SizedBox(height: 20),
            _HomeActionCard(
              icon: Icons.add_circle_outline,
              title: s.t('customer'),
              subtitle: s.t('customerSubtitle'),
              onTap: () => _openPublishFlow(context),
            ),
            _HomeActionCard(
              icon: Icons.handshake_outlined,
              title: s.t('runner'),
              subtitle: s.t('runnerSubtitle'),
              onTap: () => _openRunnerFlow(context),
            ),
            _HomeActionCard(
              icon: Icons.history_outlined,
              title: s.t('completedHistoryTitle'),
              subtitle: s.t('completedHistorySubtitle'),
              onTap: () => _openHistoryFlow(context),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('appName')),
        actions: [
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
          _RoleSettingsButton(user: currentUser),
          if (showAdmin)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Chip(
                label: Text('Admin'),
                visualDensity: VisualDensity.compact,
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
                  label: const Text('繁中'),
                  onPressed: () => widget.onLocaleChanged(const Locale('zh', 'TW')),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _HomeActionCard(
            icon: Icons.add_circle_outline,
            title: s.t('customer'),
            subtitle: s.t('customerSubtitle'),
            onTap: () => _openPublishFlow(context),
          ),
          _HomeActionCard(
            icon: Icons.handshake_outlined,
            title: s.t('runner'),
            subtitle: s.t('runnerSubtitle'),
            onTap: () => _openRunnerFlow(context),
          ),
          _HomeActionCard(
            icon: Icons.history_outlined,
            title: s.t('completedHistoryTitle'),
            subtitle: s.t('completedHistorySubtitle'),
            onTap: () => _openHistoryFlow(context),
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
        ],
      ),
    );
  }

  Future<void> _openPublishFlow(BuildContext context) async {
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerShell(),
      ),
    );
  }

  Future<void> _openRunnerFlow(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RunnerShell(),
      ),
    );
  }

  Future<void> _openHistoryFlow(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TaskHistoryScreen(),
      ),
    );
  }
}

class _RoleSettingsButton extends StatelessWidget {
  const _RoleSettingsButton({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<UserProfile?>(
      stream: UserProfileService.instance.streamProfile(uid),
      builder: (context, snapshot) {
        final role = snapshot.data?.role ?? 'both';
        return TextButton(
          onPressed: () => _showRolePicker(context, uid),
          child: Text('Role: $role'),
        );
      },
    );
  }

  Future<void> _showRolePicker(BuildContext context, String uid) async {
    final role = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Switch role'),
        content: const Text('Choose your active role in QueueGo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'customer'), child: const Text('customer')),
          TextButton(onPressed: () => Navigator.pop(context, 'runner'), child: const Text('runner')),
          FilledButton(onPressed: () => Navigator.pop(context, 'both'), child: const Text('both')),
        ],
      ),
    );
    if (role == null) return;
    await UserProfileService.instance.updateRole(uid: uid, role: role);
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
