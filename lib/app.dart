import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/i18n/app_strings.dart';
import 'features/onboarding/onboarding_screen.dart';

class QueueGoApp extends StatefulWidget {
  const QueueGoApp({super.key});

  @override
  State<QueueGoApp> createState() => _QueueGoAppState();
}

class _QueueGoAppState extends State<QueueGoApp> {
  Locale locale = const Locale('zh', 'TW');

  @override
  Widget build(BuildContext context) {
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
      home: OnboardingScreen(onLocaleChanged: (value) => setState(() => locale = value)),
    );
  }
}
