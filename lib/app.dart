import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/i18n/app_strings.dart';
import 'features/onboarding/onboarding_screen.dart';

class QueueGoApp extends StatefulWidget {
  const QueueGoApp({
    super.key,
    this.startupNotice,
    this.useMockMode = false,
  });

  final String? startupNotice;
  final bool useMockMode;

  @override
  State<QueueGoApp> createState() => _QueueGoAppState();
}

class _QueueGoAppState extends State<QueueGoApp> {
  late Locale locale;

  @override
  void initState() {
    super.initState();
    locale = _resolveDefaultLocale(PlatformDispatcher.instance.locale);
  }

  Locale _resolveDefaultLocale(Locale browserLocale) {
    if (browserLocale.languageCode == 'es') return const Locale('es', 'MX');
    if (browserLocale.languageCode == 'en') return const Locale('en');
    return const Locale('zh', 'TW');
  }

  @override
  Widget build(BuildContext context) {
    final home = OnboardingScreen(
      onLocaleChanged: (value) => setState(() => locale = value),
    );

    return MaterialApp(
      title: 'QueueGo MX',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      locale: locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStringsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _StartupNoticeWrapper(
        notice: widget.startupNotice,
        useMockMode: widget.useMockMode,
        child: home,
      ),
    );
  }
}

class _StartupNoticeWrapper extends StatelessWidget {
  const _StartupNoticeWrapper({
    required this.child,
    required this.notice,
    required this.useMockMode,
  });

  final Widget child;
  final String? notice;
  final bool useMockMode;

  @override
  Widget build(BuildContext context) {
    if (notice == null) return child;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                useMockMode ? '$notice (mock mode)' : notice!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
