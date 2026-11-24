import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'patient_store.dart';
import 'reminder_planner.dart';

/// Notificaciones del sistema (RF-11, RF-14): llegan a la hora programada
/// aunque la app esté cerrada y sin conexión a internet.
///
/// Por ahora solo funcionan en Android; en el navegador y en otras
/// plataformas todas las llamadas se ignoran sin dar error.

const String _doseChannelId = 'kardex_doses';
const String _stockChannelId = 'kardex_stock';
const String actionConfirm = 'confirm';
const String actionSnooze = 'snooze';

/// Cuánto se pospone un recordatorio con el botón «Posponer».
const Duration kSnoozeDuration = Duration(minutes: 10);

/// Se ejecuta cuando se pulsa un botón de la notificación con la app
/// cerrada. Tiene que ser una función global, no un método.
@pragma('vm:entry-point')
Future<void> notificationActionBackground(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  await SystemNotifications.handleResponse(response);
}

class SystemNotifications {
  SystemNotifications._();

  static final SystemNotifications instance = SystemNotifications._();

  /// Sube cada vez que una toma se confirma desde la notificación. La
  /// pantalla del paciente lo escucha para volver a leer sus datos.
  static final ValueNotifier<int> storageChanges = ValueNotifier<int>(0);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> init() async {
    if (!_supported || _ready) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) => handleResponse(r),
      onDidReceiveBackgroundNotificationResponse:
          notificationActionBackground,
    );
    _ready = true;
  }

  /// Pide el permiso de notificaciones (Android 13 o superior).
  Future<void> requestPermission() async {
    if (!_supported) return;
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (_) {
      // Sin permiso, la app sigue avisando desde dentro.
    }
  }

  NotificationDetails _details(AlertKind kind) {
    if (kind == AlertKind.dose) {
      return const NotificationDetails(
        android: AndroidNotificationDetails(
          _doseChannelId,
          'Recordatorios de medicamentos',
          channelDescription: 'Avisos a la hora de cada toma',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(actionConfirm, 'Confirmar toma'),
            AndroidNotificationAction(actionSnooze, 'Posponer'),
          ],
        ),
      );
    }
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _stockChannelId,
        'Medicamentos por agotarse',
        channelDescription: 'Avisos de medicamentos que se están acabando',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
  }

  Future<void> _schedule(PlannedAlert a) async {
    // La hora se pasa en UTC: es el mismo instante, y así no hace falta
    // conocer la zona horaria del teléfono.
    final when = tz.TZDateTime.from(a.at, tz.UTC);
    try {
      await _plugin.zonedSchedule(
        a.id,
        a.title,
        a.body,
        when,
        _details(a.kind),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: a.payload,
      );
    } catch (_) {
      // Si Android no permite alarmas exactas, se usa la aproximada.
      try {
        await _plugin.zonedSchedule(
          a.id,
          a.title,
          a.body,
          when,
          _details(a.kind),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: a.payload,
        );
      } catch (_) {}
    }
  }

  /// Reemplaza todos los avisos programados por [alerts]. Los pospuestos
  /// se respetan.
  Future<void> replaceAll(List<PlannedAlert> alerts) async {
    if (!_supported) return;
    try {
      await init();
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.id < kSnoozeIdBase) await _plugin.cancel(p.id);
      }
      for (final a in alerts) {
        await _schedule(a);
      }
    } catch (_) {
      // Un fallo aquí no debe romper la app.
    }
  }

  /// Quita todos los avisos (al cerrar sesión).
  Future<void> cancelAll() async {
    if (!_supported) return;
    try {
      await init();
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Aviso de farmacia cercana (RF-18), también desde segundo plano.
  Future<void> showPharmacyAlert(String body) async {
    if (!_supported) return;
    try {
      await init();
      await _plugin.show(
        kSnoozeIdBase + 95000 + (DateTime.now().millisecond % 1000),
        'Farmacia cerca',
        body,
        _details(AlertKind.lowStock),
      );
    } catch (_) {}
  }

  /// Muestra un aviso inmediato corto (confirmación de una acción).
  Future<void> _showNow(String title, String body) async {
    try {
      await _plugin.show(
        kSnoozeIdBase + 90000 + (DateTime.now().millisecond % 1000),
        title,
        body,
        _details(AlertKind.lowStock),
      );
    } catch (_) {}
  }

  /// Botones «Confirmar toma» y «Posponer» de la notificación (RF-11).
  static Future<void> handleResponse(NotificationResponse response) async {
    final action = response.actionId;
    if (action != actionConfirm && action != actionSnooze) return;
    final payload = response.payload;
    if (payload == null) return;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(payload) as Map);
      if (map['k'] != 'dose') return;
      await instance.init();
      final name = (map['name'] ?? '') as String;
      final dose = (map['dose'] ?? '') as String;

      if (action == actionConfirm) {
        final error = await PatientStore.confirmDoseInStorage(
          uid: map['uid'] as String,
          medId: map['med'] as String,
          scheduled: DateTime.parse(map['at'] as String),
        );
        storageChanges.value++;
        await instance._showNow(
          error == null ? 'Toma confirmada' : 'No se pudo confirmar',
          error ?? '$name $dose registrada en tu historial.',
        );
      } else {
        await instance._snooze(map);
      }
    } catch (_) {
      // Datos de la notificación dañados: no se hace nada.
    }
  }

  /// «Posponer»: vuelve a avisar pasados [kSnoozeDuration], siempre que
  /// la toma siga dentro de su margen de 2 horas.
  Future<void> _snooze(Map<String, dynamic> map) async {
    final scheduled = DateTime.parse(map['at'] as String);
    final again = DateTime.now().add(kSnoozeDuration);
    if (again.isAfter(scheduled.add(const Duration(hours: 2)))) {
      await _showNow('Toma omitida',
          'Ya pasó el margen de 2 horas para ${map['name']}.');
      return;
    }
    await _schedule(PlannedAlert(
      id: kSnoozeIdBase + (DateTime.now().millisecondsSinceEpoch % 80000),
      kind: AlertKind.dose,
      at: again,
      title: 'Recordatorio de medicamento',
      body: 'Pospuesto: ${doseAlertBody(
        (map['name'] ?? '') as String,
        (map['dose'] ?? '') as String,
        scheduled,
      )}',
      payload: jsonEncode(map),
    ));
  }
}
