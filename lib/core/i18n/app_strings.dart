import 'package:flutter/material.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('zh', 'TW'), Locale('en'), Locale('es', 'MX')];

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings) ?? AppStrings(const Locale('en'));
  }

  static const Map<String, Map<String, String>> _localized = {
    'zh-TW': {
      'appName': 'QueueGo MX',
      'slogan': '找人幫你現場排隊與等候',
      'chooseLanguage': '選擇語言',
      'chooseRole': '選擇身份',
      'customer': '我要發任務',
      'runner': '我要接任務',
      'admin': '管理員',
      'emailLogin': 'Email 登入',
      'mockLogin': '使用 Mock 登入',
      'terms': '服務條款',
    },
    'en': {
      'appName': 'QueueGo MX',
      'slogan': 'Get local help for lines and on-site waiting',
      'chooseLanguage': 'Choose language',
      'chooseRole': 'Select role',
      'customer': 'I need on-site help',
      'runner': 'I want to assist',
      'admin': 'Admin',
      'emailLogin': 'Email Login',
      'mockLogin': 'Use Mock Login',
      'terms': 'Terms',
    },
    'es-MX': {
      'appName': 'QueueGo MX',
      'slogan': 'Consigue ayuda local para filas y esperas presenciales',
      'chooseLanguage': 'Elegir idioma',
      'chooseRole': 'Seleccionar rol',
      'customer': 'Quiero publicar tarea',
      'runner': 'Quiero tomar tareas',
      'admin': 'Administrador',
      'emailLogin': 'Inicio con Email',
      'mockLogin': 'Entrar con Mock',
      'terms': 'Términos',
    },
  };

  String t(String key) {
    final tag = locale.countryCode == null ? locale.languageCode : '${locale.languageCode}-${locale.countryCode}';
    return _localized[tag]?[key] ?? _localized['en']![key] ?? key;
  }
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppStrings.supportedLocales.any((l) => l.languageCode == locale.languageCode && (l.countryCode == locale.countryCode || l.countryCode == null));

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
