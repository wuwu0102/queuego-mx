import 'package:flutter/material.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('es', 'MX'),
    Locale('en'),
    Locale('zh', 'TW'),
  ];

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings) ??
        AppStrings(const Locale('en'));
  }

  static const Map<String, Map<String, String>> _localized = {
    'zh-TW': {
      'appName': 'QueueGo MX',
      'sloganMvp': '可實際運作的任務媒合 MVP',
      'chooseLanguage': '選擇語言',
      'customer': '我要發任務',
      'runner': '我要接任務',
      'admin': '管理員',
      'customerSubtitle': '發佈任務、查看交接碼與完成狀態',
      'runnerSubtitle': '接單、到場回報、更新進度與交接完成',
      'adminSubtitle': '查看示範管理頁',
      'terms': '服務條款',
      'firebaseMockNotice': '目前使用本地 mock repository（記憶體）儲存任務。',
      'createTask': '發任務',
      'myTasks': '我的任務',
      'publishTask': '發布任務',
      'mvpFormTitle': '填寫任務資訊',
      'locationInput': 'Google Maps 連結或地點文字',
      'taskDescription': '任務內容',
      'onsiteInstructions': '現場指示',
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
      'taskAccepted': '已接單，任務已移至我的進行中。',
      'activeTasks': '進行中任務',
      'noOpenTasks': '目前沒有可接任務。',
      'noActiveTasks': '目前沒有進行中任務。',
      'startTime': '開始時間',
      'price': '金額',
      'arriveNow': '我已到現場',
      'arriveDialogTitle': '到場確認',
      'arrivePositionHint': '現場描述（例如：目前排第 8 位）',
      'photoMockHint': '照片網址（mock）',
      'saveArrived': '儲存到場回報',
      'arrivedSaved': '到場資訊已送出。',
      'updateProgress': '更新進度',
      'progressHint': '例如：已排到第 5 個，預計 30 分鐘',
      'progressSaved': '進度已更新。',
      'handoffCode': '交接碼',
      'enterHandoffCode': '輸入交接碼完成任務',
      'completeByCode': '驗證並完成',
      'codeMismatch': '交接碼不正確，無法完成。',
      'taskCompleted': '任務已完成。',
      'checkInPhoto': '到場照片',
      'latestProgress': '最新進度',
      'ratingPrompt': '請給這次協助評分（僅 UI）',
      'status_open': 'open',
      'status_accepted': 'accepted',
      'status_arrived': 'arrived',
      'status_inProgress': 'in_progress',
      'status_completed': 'completed',
    },
    'en': {
      'appName': 'QueueGo MX',
      'sloganMvp': 'Working task-matching MVP',
      'chooseLanguage': 'Choose language',
      'customer': 'I want to post a task',
      'runner': 'I want to take tasks',
      'admin': 'Admin',
      'customerSubtitle': 'Post tasks, view handoff code, and completion status',
      'runnerSubtitle': 'Accept tasks, check in, update progress, and complete handoff',
      'adminSubtitle': 'Open demo admin page',
      'terms': 'Terms',
      'firebaseMockNotice': 'Tasks are stored in a local in-memory mock repository.',
      'createTask': 'Create',
      'myTasks': 'My Tasks',
      'publishTask': 'Publish Task',
      'mvpFormTitle': 'Fill in task details',
      'locationInput': 'Google Maps link or location text',
      'taskDescription': 'Task description',
      'onsiteInstructions': 'On-site instructions',
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
      'taskAccepted': 'Task accepted and moved to active tasks.',
      'activeTasks': 'Active Tasks',
      'noOpenTasks': 'No open tasks right now.',
      'noActiveTasks': 'No active tasks right now.',
      'startTime': 'Start time',
      'price': 'Price',
      'arriveNow': 'I have arrived',
      'arriveDialogTitle': 'Arrival check-in',
      'arrivePositionHint': 'On-site note (e.g. currently #8 in line)',
      'photoMockHint': 'Photo URL (mock)',
      'saveArrived': 'Save arrival update',
      'arrivedSaved': 'Arrival details submitted.',
      'updateProgress': 'Update progress',
      'progressHint': 'Example: now #5 in queue, ~30 mins left',
      'progressSaved': 'Progress updated.',
      'handoffCode': 'Handoff code',
      'enterHandoffCode': 'Enter handoff code to complete',
      'completeByCode': 'Verify & complete',
      'codeMismatch': 'Handoff code is invalid.',
      'taskCompleted': 'Task marked as completed.',
      'checkInPhoto': 'Check-in photo',
      'latestProgress': 'Latest progress',
      'ratingPrompt': 'Rate this task (UI only)',
      'status_open': 'open',
      'status_accepted': 'accepted',
      'status_arrived': 'arrived',
      'status_inProgress': 'in_progress',
      'status_completed': 'completed',
    },
    'es-MX': {
      'appName': 'QueueGo MX',
      'sloganMvp': 'MVP funcional de matching de tareas',
      'chooseLanguage': 'Elegir idioma',
      'customer': 'Quiero publicar tarea',
      'runner': 'Quiero tomar tareas',
      'admin': 'Administrador',
      'customerSubtitle': 'Publica tareas, ve código de entrega y estado final',
      'runnerSubtitle': 'Aceptar, llegar al sitio, reportar avance y completar',
      'adminSubtitle': 'Abrir panel de administrador demo',
      'terms': 'Términos',
      'firebaseMockNotice': 'Las tareas usan un repositorio mock local en memoria.',
      'createTask': 'Crear',
      'myTasks': 'Mis tareas',
      'publishTask': 'Publicar tarea',
      'mvpFormTitle': 'Completa los datos de la tarea',
      'locationInput': 'Enlace de Google Maps o texto del lugar',
      'taskDescription': 'Descripción de la tarea',
      'onsiteInstructions': 'Instrucciones en sitio',
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
      'taskAccepted': 'Tarea aceptada y movida a activas.',
      'activeTasks': 'Tareas activas',
      'noOpenTasks': 'No hay tareas abiertas ahora.',
      'noActiveTasks': 'No hay tareas activas ahora.',
      'startTime': 'Hora de inicio',
      'price': 'Monto',
      'arriveNow': 'Ya llegué al lugar',
      'arriveDialogTitle': 'Confirmación de llegada',
      'arrivePositionHint': 'Nota en sitio (ej: voy en el lugar 8)',
      'photoMockHint': 'URL de foto (mock)',
      'saveArrived': 'Guardar llegada',
      'arrivedSaved': 'Llegada guardada.',
      'updateProgress': 'Actualizar avance',
      'progressHint': 'Ejemplo: ya voy en el #5, faltan 30 min',
      'progressSaved': 'Avance actualizado.',
      'handoffCode': 'Código de entrega',
      'enterHandoffCode': 'Ingresa el código para completar',
      'completeByCode': 'Verificar y completar',
      'codeMismatch': 'Código incorrecto.',
      'taskCompleted': 'Tarea completada.',
      'checkInPhoto': 'Foto de llegada',
      'latestProgress': 'Último avance',
      'ratingPrompt': 'Califica esta tarea (solo UI)',
      'status_open': 'open',
      'status_accepted': 'accepted',
      'status_arrived': 'arrived',
      'status_inProgress': 'in_progress',
      'status_completed': 'completed',
    },
  };

  String t(String key) {
    final tag = locale.countryCode == null
        ? locale.languageCode
        : '${locale.languageCode}-${locale.countryCode}';
    return _localized[tag]?[key] ?? _localized['en']![key] ?? key;
  }

  String statusLabel(String statusKey) => t('status_$statusKey');
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales.any(
        (l) =>
            l.languageCode == locale.languageCode &&
            (l.countryCode == locale.countryCode || l.countryCode == null),
      );

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
