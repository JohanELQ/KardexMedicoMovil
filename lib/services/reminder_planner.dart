import 'dart:convert';

import '../core/format.dart';
import '../models/medication.dart';

/// Tipo de aviso que se programa en el sistema.
enum AlertKind { dose, lowStock }

/// Identificadores de las notificaciones programadas. Los recordatorios de
/// toma usan desde 1, los avisos de stock desde 100000 y los pospuestos
/// desde 200000, así se pueden reprogramar unos sin borrar los otros.
const int kDoseIdBase = 1;
const int kStockIdBase = 100000;
const int kSnoozeIdBase = 200000;

/// Un aviso que se programará en el sistema para una hora concreta.
class PlannedAlert {
  final int id;
  final AlertKind kind;
  final DateTime at;
  final String title;
  final String body;
  final String payload;

  const PlannedAlert({
    required this.id,
    required this.kind,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
  });

  PlannedAlert withId(int newId) => PlannedAlert(
        id: newId,
        kind: kind,
        at: at,
        title: title,
        body: body,
        payload: payload,
      );
}

/// Texto del recordatorio de una toma (RF-11).
String doseAlertBody(String name, String dose, DateTime at) =>
    'Es hora de tomar $name $dose (${formatTime12(at.hour, at.minute)}).';

/// Datos que viajan dentro de la notificación de una toma, para poder
/// confirmarla o posponerla sin abrir la app.
String dosePayload({
  required String uid,
  required String medId,
  required DateTime at,
  required String name,
  required String dose,
}) =>
    jsonEncode({
      'k': 'dose',
      'uid': uid,
      'med': medId,
      'at': at.toIso8601String(),
      'name': name,
      'dose': dose,
    });

/// RF-11: calcula los recordatorios de las tomas de los próximos [days]
/// días.
///
/// - No programa tomas que ya pasaron ni las de hoy que ya se confirmaron.
/// - Se detiene cuando se acabaría el stock: no tiene sentido recordar
///   una toma de un medicamento que ya no queda.
/// - Se recalcula cada vez que cambian los medicamentos o se abre la app,
///   así la ventana de [days] días se va renovando.
List<PlannedAlert> planDoseAlerts({
  required String uid,
  required DateTime now,
  required List<Medication> medications,
  required List<ScheduledDose> todayDoses,
  int days = 7,
  int maxAlerts = 120,
}) {
  final found = <PlannedAlert>[];

  for (final med in medications) {
    var remaining = med.totalDoses;
    for (var d = 0; d < days && remaining > 0; d++) {
      for (final t in med.times) {
        if (remaining <= 0) break;
        final p = parseHm(t);
        final at = DateTime(now.year, now.month, now.day + d, p[0], p[1]);
        if (!at.isAfter(now)) continue;
        if (at.isBefore(med.createdAt)) continue;
        if (d == 0 && _alreadyTaken(todayDoses, med.id, at)) continue;
        found.add(PlannedAlert(
          id: 0,
          kind: AlertKind.dose,
          at: at,
          title: 'Recordatorio de medicamento',
          body: doseAlertBody(med.name, med.dose, at),
          payload: dosePayload(
            uid: uid,
            medId: med.id,
            at: at,
            name: med.name,
            dose: med.dose,
          ),
        ));
        remaining--;
      }
    }
  }

  found.sort((a, b) => a.at.compareTo(b.at));
  final limited = found.take(maxAlerts).toList();
  return [
    for (var i = 0; i < limited.length; i++) limited[i].withId(kDoseIdBase + i),
  ];
}

bool _alreadyTaken(List<ScheduledDose> today, String medId, DateTime at) {
  return today.any((d) =>
      d.medication.id == medId &&
      d.scheduled == at &&
      d.status == DoseStatus.taken);
}
