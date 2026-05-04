import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/auth_gate.dart';
import '../../core/services/firestore_task_service.dart';
import '../../core/services/user_profile_service.dart';
import 'auth_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../customer/customer_shell.dart';
import '../runner/runner_shell.dart';
import '../shared/privacy_screen.dart';
import '../shared/terms_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _rolePromptedUid;
  String? _adminWelcomedUid;
  bool _processingRedirect = false;

  @override
  void initState() {
    super.initState();
    _processGoogleRedirectLogin();
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
            'Administrador conectado',
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

  Future<void> _processGoogleRedirectLogin() async {
    if (_processingRedirect) return;
    _processingRedirect = true;
    try {
      final didRedirectLogin = await handleGoogleSignInRedirect();
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = isFormallyLoggedIn(user);
      if (!didRedirectLogin && !isLoggedIn) return;
      final pendingAction = await consumePendingAuthAction();
      if (!mounted) return;
      final s = AppStrings.of(context);
      await _closeResidualLoginModal();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('loginSuccess'))),
      );
      if (pendingAction != null) {
        await _resumePendingAction(pendingAction);
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final detail = error.message?.trim();
      final message = 'Google redirect login failed (${error.code})'
          '${detail == null || detail.isEmpty ? '' : ': $detail'}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await clearPendingAuthAction();
    } finally {
      _processingRedirect = false;
    }
  }

  Future<void> _closeResidualLoginModal() async {
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).maybePop();
  }

  Future<void> _resumePendingAction(PendingAuthAction action) async {
    if (!mounted) return;
    switch (action) {
      case PendingAuthAction.publishTask:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomerShell(initialTab: 0),
          ),
        );
        return;
      case PendingAuthAction.myTasks:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomerShell(initialTab: 1),
          ),
        );
        return;
      case PendingAuthAction.takeTask:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RunnerShell(initialTab: 0),
          ),
        );
        return;
      case PendingAuthAction.myApplications:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RunnerShell(initialTab: 1),
          ),
        );
        return;
      case PendingAuthAction.activeTasks:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RunnerShell(initialTab: 2),
          ),
        );
        return;
    }
  }

  Future<String?> _showRoleDialog(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = switch (languageCode) {
      'en' => 'What do you want to do in QueueGo?',
      _ => '¿Qué quieres hacer en QueueGo?',
    };
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'customer'), child: const Text('Publicar tareas')),
          TextButton(onPressed: () => Navigator.pop(context, 'runner'), child: const Text('Tomar tareas')),
          FilledButton(onPressed: () => Navigator.pop(context, 'both'), child: const Text('Ambas')),
        ],
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, User? currentUser) {
    final s = AppStrings.of(context);
    final isLoggedIn = isFormallyLoggedIn(currentUser);
    final email = _maskEmail(currentUser?.email);
    final showAdmin = isAdminUser(currentUser);
    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: Text(s.t('appName')),
          actions: [
            TextButton(
              onPressed: () async {
                await showLoginModal(context);
              },
              child: Text(s.t('loginAction')),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsScreen()),
              ),
              child: Text(s.t('terms')),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyScreen()),
              ),
              child: Text(s.t('privacy')),
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
            const SizedBox(height: 8),
            Text(s.t('sloganSubtitle')),
            const SizedBox(height: 16),
            Text(s.t('chooseLanguage')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _languageChips(showChinese: false),
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
              icon: Icons.list_alt_outlined,
              title: s.t('completedHistoryTitle'),
              subtitle: s.t('completedHistorySubtitle'),
              onTap: () => _openRunnerFlow(context),
            ),
            const SizedBox(height: 8),
            const _HomeInfoSection(),
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
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
            child: Text(s.t('privacy')),
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
          const SizedBox(height: 8),
          Text(s.t('sloganSubtitle')),
          const SizedBox(height: 16),
          Text(s.t('chooseLanguage')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _languageChips(showChinese: showAdmin),
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
            icon: Icons.list_alt_outlined,
            title: s.t('completedHistoryTitle'),
            subtitle: s.t('completedHistorySubtitle'),
            onTap: () => _openRunnerFlow(context),
          ),
          const SizedBox(height: 8),
          const _HomeInfoSection(),
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

  String _maskEmail(String? email) {
    final value = email?.trim() ?? '';
    if (!value.contains('@')) return value;
    final parts = value.split('@');
    final name = parts.first;
    if (name.isEmpty) return '***@${parts.last}';
    if (name.length <= 2) {
      return '${name[0]}***@${parts.last}';
    }
    return '${name.substring(0, 2)}***@${parts.last}';
  }

  List<Widget> _languageChips({required bool showChinese}) {
    return [
      ActionChip(
        label: const Text('Español MX'),
        onPressed: () => widget.onLocaleChanged(const Locale('es', 'MX')),
      ),
      ActionChip(
        label: const Text('English'),
        onPressed: () => widget.onLocaleChanged(const Locale('en')),
      ),
      if (showChinese)
        ActionChip(
          label: const Text('中文'),
          onPressed: () => widget.onLocaleChanged(const Locale('zh', 'TW')),
        ),
    ];
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
        final languageCode = Localizations.localeOf(context).languageCode;
        final roleLabel = switch (languageCode) {
          'en' => 'Role: $role',
          _ => 'Rol: $role',
        };
        return TextButton(
          onPressed: () => _showRolePicker(context, uid),
          child: Text(roleLabel),
        );
      },
    );
  }

  Future<void> _showRolePicker(BuildContext context, String uid) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = switch (languageCode) {
      'en' => 'Switch role',
      _ => 'Cambiar rol',
    };
    final content = switch (languageCode) {
      'en' => 'Choose your active role in QueueGo.',
      _ => 'Elige tu rol activo en QueueGo.',
    };
    final role = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'customer'),
            child: Text(languageCode == 'en' ? 'Customer' : 'Cliente'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'runner'),
            child: const Text('Runner'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'both'),
            child: Text(languageCode == 'en' ? 'Both' : 'Ambos'),
          ),
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

class _HomeInfoSection extends StatelessWidget {
  const _HomeInfoSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Text('Información adicional', style: Theme.of(context).textTheme.titleMedium),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [
          Text('Seguridad y recomendaciones', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          const Text('• Proyecto piloto en Guadalajara. Coordina siempre por la plataforma.'),
          const SizedBox(height: 10),
          Text('Texto para compartir', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          const Text('QueueGo MX: publica una tarea o únete como Runner en Guadalajara.'),
          const SizedBox(height: 10),
          Text('Precios de referencia', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          StreamBuilder<int>(
            stream: FirestoreTaskService.instance.streamTasksCompletedCount(),
            builder: (context, snapshot) {
              final completed = snapshot.data ?? 0;
              if (completed <= 0) {
                return const Text('Aún no hay tareas completadas.');
              }
              return Text('Tareas completadas registradas: $completed');
            },
          ),
        ],
      ),
    );
  }
}
