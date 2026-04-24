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
      'sloganMvp': '最簡單可用的任務發布＋接單',
      'chooseLanguage': '選擇語言',
      'customer': '我要發任務',
      'runner': '我要接任務',
      'admin': '管理員',
      'customerSubtitle': '建立任務並查看我的任務狀態',
      'runnerSubtitle': '瀏覽可接任務並開始處理',
      'adminSubtitle': '查看示範管理頁',
      'terms': '服務條款',
      'firebaseMockNotice': '目前使用本地 mock repository（記憶體）儲存任務。',
      'createTask': '發任務',
      'myTasks': '我的任務',
      'publishTask': '發布任務',
      'mvpFormTitle': '填寫 4 個欄位即可發布',
      'locationInput': 'Google Maps 連結或地點文字',
      'taskDescription': '任務內容',
      'startTimeInput': '開始時間（YYYY-MM-DD HH:mm）',
      'priceMxnInput': '願意支付金額（MXN）',
      'publishTaskButton': '發布任務',
      'taskPublished': '任務已發布，已切換到我的任務。',
      'requiredField': '此欄位必填',
      'invalidPrice': '請輸入有效金額',
      'startTimeFormatHint': '時間格式錯誤，請輸入 YYYY-MM-DD HH:mm',
      'noTasksYet': '目前還沒有任務。',
      'availableTasks': '可接任務',
      'acceptTask': '接單',
      'taskAccepted': '已接單，任務已移至進行中。',
      'inProgressTasks': '進行中任務',
      'markCompleted': '完成任務',
      'taskCompleted': '任務已完成。',
      'noOpenTasks': '目前沒有可接任務。',
      'noInProgressTasks': '目前沒有進行中任務。',
      'startTime': '開始時間',
      'price': '金額',
      'status_open': 'open',
      'status_accepted': 'accepted',
      'status_completed': 'completed',
    },
    'en': {
      'appName': 'QueueGo MX',
      'slogan': 'Get local help for lines and on-site waiting',
      'sloganMvp': 'Simple task posting + task taking MVP',
      'chooseLanguage': 'Choose language',
      'customer': 'I want to post a task',
      'runner': 'I want to take tasks',
      'admin': 'Admin',
      'customerSubtitle': 'Create tasks and track status in My Tasks',
      'runnerSubtitle': 'Browse open tasks and accept quickly',
      'adminSubtitle': 'Open demo admin page',
      'terms': 'Terms',
      'firebaseMockNotice': 'Tasks are stored in a local in-memory mock repository.',
      'createTask': 'Create',
      'myTasks': 'My Tasks',
      'publishTask': 'Publish Task',
      'mvpFormTitle': 'Only 4 fields to publish',
      'locationInput': 'Google Maps link or location text',
      'taskDescription': 'Task description',
      'startTimeInput': 'Start time (YYYY-MM-DD HH:mm)',
      'priceMxnInput': 'Offer price (MXN)',
      'publishTaskButton': 'Publish',
      'taskPublished': 'Task published. Redirected to My Tasks.',
      'requiredField': 'This field is required',
      'invalidPrice': 'Enter a valid price',
      'startTimeFormatHint': 'Invalid format. Use YYYY-MM-DD HH:mm',
      'noTasksYet': 'No tasks yet.',
      'availableTasks': 'Available Tasks',
      'acceptTask': 'Accept',
      'taskAccepted': 'Task accepted and moved to in-progress.',
      'inProgressTasks': 'In-Progress Tasks',
      'markCompleted': 'Mark Completed',
      'taskCompleted': 'Task marked as completed.',
      'noOpenTasks': 'No open tasks right now.',
      'noInProgressTasks': 'No accepted tasks yet.',
      'startTime': 'Start time',
      'price': 'Price',
      'status_open': 'open',
      'status_accepted': 'accepted',
      'status_completed': 'completed',
    },
    'es-MX': {
      'appName': 'QueueGo MX',
      'slogan': 'Consigue ayuda local para filas y esperas presenciales',
      'sloganMvp': 'MVP simple para publicar y tomar tareas',
      'chooseLanguage': 'Elegir idioma',
      'customer': 'Quiero publicar tarea',
      'runner': 'Quiero tomar tareas',
      'admin': 'Administrador',
      'customerSubtitle': 'Publica tareas y revisa su estado',
      'runnerSubtitle': 'Ve tareas abiertas y acepta rápido',
      'adminSubtitle': 'Abrir panel de administrador demo',
      'terms': 'Términos',
      'firebaseMockNotice': 'Las tareas usan un repositorio mock local en memoria.',
      'createTask': 'Crear',
      'myTasks': 'Mis tareas',
      'publishTask': 'Publicar tarea',
      'mvpFormTitle': 'Solo 4 campos para publicar',
      'locationInput': 'Enlace de Google Maps o texto del lugar',
      'taskDescription': 'Descripción de la tarea',
      'startTimeInput': 'Hora de inicio (YYYY-MM-DD HH:mm)',
      'priceMxnInput': 'Pago ofrecido (MXN)',
      'publishTaskButton': 'Publicar',
      'taskPublished': 'Tarea publicada. Redirigido a Mis tareas.',
      'requiredField': 'Este campo es obligatorio',
      'invalidPrice': 'Ingresa un monto válido',
      'startTimeFormatHint': 'Formato inválido. Usa YYYY-MM-DD HH:mm',
      'noTasksYet': 'Aún no hay tareas.',
      'availableTasks': 'Tareas disponibles',
      'acceptTask': 'Aceptar',
      'taskAccepted': 'Tarea aceptada y movida a en progreso.',
      'inProgressTasks': 'Tareas en progreso',
      'markCompleted': 'Marcar completada',
      'taskCompleted': 'Tarea marcada como completada.',
      'noOpenTasks': 'No hay tareas abiertas ahora.',
      'noInProgressTasks': 'No hay tareas en progreso.',
      'startTime': 'Hora de inicio',
      'price': 'Monto',
      'status_open': 'open',
      'status_accepted': 'accepted',
      'status_completed': 'completed',
    },
  };

  String t(String key) {
    final tag = locale.countryCode == null ? locale.languageCode : '${locale.languageCode}-${locale.countryCode}';
    return _localized[tag]?[key] ?? _localized['en']![key] ?? key;
  }

  String statusLabel(String statusKey) => t('status_$statusKey');
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
