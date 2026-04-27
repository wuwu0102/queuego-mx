import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/services/auth_gate.dart';
import '../../core/services/firestore_task_service.dart';
import '../../core/services/user_profile_service.dart';

const _googleRedirectAnonymousUidKey = 'google_redirect_previous_anonymous_uid';
const _googleRedirectPendingKey = 'google_redirect_pending_login';

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
    await _runAuthAction(
      (email, password) => _signInProgressively(email: email, password: password),
      successMessage: null,
      notifyLoginSuccess: true,
    );
  }

  Future<void> _register() async {
    await _runAuthAction(
      (email, password) => _registerProgressively(email: email, password: password),
      successMessage: AppStrings.of(context).t('authAccountCreated'),
    );
  }

  Future<void> _loginWithGoogle() async {
    final s = AppStrings.of(context);
    setState(() => _loading = true);
    final auth = FirebaseAuth.instance;
    final current = auth.currentUser;
    final wasAnonymous = current?.isAnonymous ?? false;
    final previousUid = wasAnonymous ? (current?.uid ?? '') : '';

    try {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      if (kIsWeb) {
        final credential = await auth.signInWithPopup(provider);
        await _migrateAnonymousDataIfNeeded(
          previousAnonymousUid: previousUid,
          currentUser: credential.user,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.t('loginSuccess'))),
        );
        Navigator.pop(context, true);
        return;
      } else {
        final credential = await auth.signInWithProvider(provider);
        await _migrateAnonymousDataIfNeeded(
          previousAnonymousUid: previousUid,
          currentUser: credential.user,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.t('loginSuccess'))),
        );
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final detail = error.message?.trim();
      final errorWithDetail = '(${error.code})'
          '${detail == null || detail.isEmpty ? '' : ': $detail'}';
      const popupRelatedErrors = {
        'popup-blocked',
        'popup-closed-by-user',
        'cancelled-popup-request',
        'web-context-cancelled',
      };
      final message = popupRelatedErrors.contains(error.code)
          ? 'No se pudo abrir Google. Permite ventanas emergentes o abre esta página en Chrome/Safari.\n$errorWithDetail'
          : '${s.t('authUnknownError')} $errorWithDetail';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<UserCredential> _signInProgressively({
    required String email,
    required String password,
  }) async {
    final auth = FirebaseAuth.instance;
    final current = auth.currentUser;
    final wasAnonymous = current?.isAnonymous ?? false;
    final previousUid = wasAnonymous ? (current?.uid ?? '') : '';
    final credential = EmailAuthProvider.credential(email: email, password: password);

    UserCredential result;
    if (wasAnonymous && current != null) {
      try {
        result = await current.linkWithCredential(credential);
      } on FirebaseAuthException catch (error) {
        if (error.code != 'credential-already-in-use' && error.code != 'email-already-in-use') {
          rethrow;
        }
        result = await auth.signInWithEmailAndPassword(email: email, password: password);
      }
    } else {
      result = await auth.signInWithEmailAndPassword(email: email, password: password);
    }

    await _migrateAnonymousDataIfNeeded(
      previousAnonymousUid: previousUid,
      currentUser: result.user,
    );
    return result;
  }

  Future<UserCredential> _registerProgressively({
    required String email,
    required String password,
  }) async {
    final auth = FirebaseAuth.instance;
    final current = auth.currentUser;
    final wasAnonymous = current?.isAnonymous ?? false;
    final previousUid = wasAnonymous ? (current?.uid ?? '') : '';
    final credential = EmailAuthProvider.credential(email: email, password: password);

    UserCredential result;
    if (wasAnonymous && current != null) {
      result = await current.linkWithCredential(credential);
    } else {
      result = await auth.createUserWithEmailAndPassword(email: email, password: password);
    }

    await _migrateAnonymousDataIfNeeded(
      previousAnonymousUid: previousUid,
      currentUser: result.user,
    );
    return result;
  }

  Future<void> _migrateAnonymousDataIfNeeded({
    required String previousAnonymousUid,
    required User? currentUser,
  }) async {
    final nextUid = currentUser?.uid ?? '';
    if (previousAnonymousUid.isEmpty || nextUid.isEmpty || previousAnonymousUid == nextUid) {
      return;
    }
    await FirestoreTaskService.instance.migrateAnonymousUserData(
      fromAnonymousUid: previousAnonymousUid,
      toFormalUid: nextUid,
      formalEmail: currentUser?.email,
      formalDisplayName: currentUser?.displayName,
    );
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
      final baseMessage = switch (code) {
        'wrong-password' || 'invalid-credential' => s.t('authWrongPassword'),
        'user-not-found' => s.t('authUserNotFound'),
        _ => s.t('authUnknownError'),
      };
      final detail = error.message?.trim();
      final message = '$baseMessage ($code)'
          '${detail == null || detail.isEmpty ? '' : ': $detail'}';
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
                'Continúa para publicar o tomar tareas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text('Crea una cuenta simple para mantener la información segura.'),
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
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _loginWithGoogle,
                  icon: const Icon(Icons.login),
                  label: Text(s.t('continueWithGoogle')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context, false),
                  child: Text(s.t('continueBrowsing')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> handleGoogleSignInRedirect() async {
  final auth = FirebaseAuth.instance;
  final prefs = await SharedPreferences.getInstance();
  final hadPendingRedirect = prefs.getBool(_googleRedirectPendingKey) ?? false;
  final credential = await auth.getRedirectResult();
  final redirectUser = credential.user;
  final currentUser = auth.currentUser;
  final resolvedUser = redirectUser ?? currentUser;
  if (resolvedUser == null || !isFormallyLoggedIn(resolvedUser)) {
    return false;
  }
  final previousUid = prefs.getString(_googleRedirectAnonymousUidKey) ?? '';
  await prefs.remove(_googleRedirectAnonymousUidKey);
  await prefs.remove(_googleRedirectPendingKey);
  if (previousUid.isNotEmpty && previousUid != resolvedUser.uid) {
    await FirestoreTaskService.instance.migrateAnonymousUserData(
      fromAnonymousUid: previousUid,
      toFormalUid: resolvedUser.uid,
      formalEmail: resolvedUser.email,
      formalDisplayName: resolvedUser.displayName,
    );
  }
  return redirectUser != null || hadPendingRedirect || isFormallyLoggedIn(currentUser);
}

Future<bool> showLoginModal(BuildContext context) async {
  final loggedIn = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const LoginModal(),
  );
  return loggedIn ?? false;
}
