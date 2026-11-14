import 'dart:convert';

import '../core/format.dart';
import '../models/medication.dart';
import 'reminder_planner.dart';

/// Hora del día a la que se muestra el aviso de medicamento por agotarse.
const int kStockAlertHour = 9;

/// Texto del aviso de stock bajo (RF-14): nombre y días restantes.
String stockAlertBody(String name, int days) {
  if (days <= 0) return 'Se agotó $name. Repón el medicamento.';
  return '$name: ${daysRemainingText(days).toLowerCase()}. '
      'Repón el medicamento pronto.';
}

/// RF-14: programa el aviso de medicamento por agotarse, para que llegue
/// aunque la app esté cerrada.
///
/// - Se avisa cuando los días restantes (RF-13) llegan al [threshold]
///   configurado por el usuario. Si ya llegaron, el aviso sale a la
///   próxima 9:00.
/// - Es un aviso por día como máximo (RF-14) y se programan hasta
///   [alertsPerMedication] días seguidos por medicamento.
/// - Los días que indica cada aviso son una proyección: suponen que el
///   paciente toma todas sus dosis. Cada vez que se abre la app o cambian
///   los medicamentos se vuelve a calcular con el stock real.
List<PlannedAlert> planStockAlerts({
  required String uid,
  required DateTime now,
  required List<Medication> medications,
  required int threshold,
  int windowDays = 30,
  int alertsPerMedication = 3,
}) {
  final found = <PlannedAlert>[];

  for (final med in medications) {
    if (med.dosesPerDay == 0) continue;
    final days = med.daysRemaining;

    // Cuántos días faltan para llegar al umbral (0 si ya se alcanzó).
    var start = days > threshold ? days - threshold : 0;

    // Si hoy ya pasó la hora del aviso, el primero sale mañana.
    final todayAt = DateTime(now.year, now.month, now.day, kStockAlertHour);
    if (start == 0 && !todayAt.isAfter(now)) start = 1;

    for (var k = 0; k < alertsPerMedication; k++) {
      final offset = start + k;
      if (offset > windowDays) break;
      final projected = days - offset;
      if (projected < 0) break;
      found.add(PlannedAlert(
        id: 0,
        kind: AlertKind.lowStock,
        at: DateTime(now.year, now.month, now.day + offset, kStockAlertHour),
        title: 'Medicamento por agotarse',
        body: stockAlertBody(med.name, projected),
        payload: jsonEncode({'k': 'stock', 'uid': uid, 'med': med.id}),
      ));
    }
  }

  found.sort((a, b) => a.at.compareTo(b.at));
  return [
    for (var i = 0; i < found.length; i++) found[i].withId(kStockIdBase + i),
  ];
}
