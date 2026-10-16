import 'package:flutter/foundation.dart';

import '../core/format.dart';
import '../models/app_user.dart';
import '../models/medication.dart';

/// Datos del paciente en memoria: perfil médico, medicamentos e
/// historial de tomas.
///
/// Por ahora todo vive en memoria mientras la app está abierta (igual
/// que `MockAuthService`). Cuando se conecte `sqflite` (RNF-02) o
/// Firestore, solo hay que cambiar el interior de estos métodos: las
/// pantallas no necesitan cambios.
class PatientStore extends ChangeNotifier {
  PatientStore({required this.uid});

  final String uid;

  MedicalProfile? _profile;
  String? _qrToken;
  final List<Medication> _medications = [];
  final List<DoseLog> _logs = [];
  int _nextId = 1;

  // ---------------------------------------------------------------
  // Perfil médico y QR (RF-04, RF-05, RF-06)
  // ---------------------------------------------------------------

  MedicalProfile? get profile => _profile;
  bool get hasProfile => _profile != null;

  /// Contenido del QR de emergencia. Es null mientras no exista un
  /// perfil guardado (RF-06: el QR se genera cuando hay perfil).
  String? get qrData =>
      _qrToken == null ? null : 'KARDEX-EMERGENCIA:$uid:$_qrToken';

  /// Identificador corto que se muestra debajo del QR.
  String get qrShortId =>
      (_qrToken ?? '').toUpperCase().padRight(6, '-').substring(0, 6);

  /// Guarda el perfil y genera un QR nuevo. El anterior deja de ser
  /// válido porque el token cambia en cada guardado (RF-06).
  void saveProfile(MedicalProfile profile) {
    _profile = profile;
    _qrToken = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Medicamentos (RF-10, RF-21)
  // ---------------------------------------------------------------

  List<Medication> get medications => List.unmodifiable(_medications);

  void addMedication({
    required String name,
    required String dose,
    required List<String> times,
    required int totalDoses,
  }) {
    final sorted = [...times]..sort();
    _medications.add(Medication(
      id: 'med-${_nextId++}',
      name: name.trim(),
      dose: dose.trim(),
      times: sorted,
      totalDoses: totalDoses,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void updateMedication({
    required String id,
    required String name,
    required String dose,
    required List<String> times,
    required int totalDoses,
  }) {
    final index = _medications.indexWhere((m) => m.id == id);
    if (index < 0) return;
    final old = _medications[index];
    final sorted = [...times]..sort();
    final timesChanged = !listEquals(old.times, sorted);
    _medications[index] = old.copyWith(
      name: name.trim(),
      dose: dose.trim(),
      times: sorted,
      totalDoses: totalDoses,
      // Si cambian los horarios, las tomas de hoy que ya pasaron no
      // cuentan como omitidas: se empieza a contar desde ahora.
      createdAt: timesChanged ? DateTime.now() : old.createdAt,
    );
    notifyListeners();
  }

  void deleteMedication(String id) {
    _medications.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Tomas del día (RF-11 a RF-13, RF-15)
  // ---------------------------------------------------------------

  /// Tomas programadas para el día de [now], ordenadas por hora. Solo
  /// cuentan las tomas desde que se registró el medicamento.
  List<ScheduledDose> dosesForDay(DateTime now) {
    final result = <ScheduledDose>[];
    for (final med in _medications) {
      for (final t in med.times) {
        final p = parseHm(t);
        final scheduled = DateTime(now.year, now.month, now.day, p[0], p[1]);
        if (scheduled.isBefore(med.createdAt)) continue;
        result.add(ScheduledDose(
          medication: med,
          scheduled: scheduled,
          status: _statusFor(med.id, scheduled, now),
        ));
      }
    }
    result.sort((a, b) => a.scheduled.compareTo(b.scheduled));
    return result;
  }

  DoseStatus _statusFor(String medId, DateTime scheduled, DateTime now) {
    final taken = _logs.any(
      (l) => l.medicationId == medId && l.scheduled == scheduled,
    );
    if (taken) return DoseStatus.taken;
    // RF-15: omitida si no se confirmó dentro de las 2 horas siguientes.
    if (now.isAfter(scheduled.add(const Duration(hours: 2)))) {
      return DoseStatus.missed;
    }
    return DoseStatus.pending;
  }

  /// Próxima toma pendiente de un medicamento (hoy), o null si no hay.
  ScheduledDose? nextPendingFor(String medicationId, DateTime now) {
    for (final d in dosesForDay(now)) {
      if (d.medication.id == medicationId && d.status == DoseStatus.pending) {
        return d;
      }
    }
    return null;
  }

  /// RF-12: confirma una toma, descuenta una unidad del stock y la
  /// registra en el historial. Devuelve null si todo salió bien, o un
  /// mensaje de error para mostrar al usuario.
  String? confirmDose(ScheduledDose dose) {
    if (dose.status == DoseStatus.taken) {
      return 'Esta toma ya fue confirmada';
    }
    if (dose.status == DoseStatus.missed) {
      return 'Esta toma ya pasó de las 2 horas y quedó como omitida';
    }
    final index = _medications.indexWhere((m) => m.id == dose.medication.id);
    if (index < 0) return 'Este medicamento ya no existe';
    final med = _medications[index];
    if (med.totalDoses <= 0) {
      return 'No quedan dosis disponibles de ${med.name}';
    }

    // El conteo nunca baja de 0 (RF-12).
    _medications[index] = med.copyWith(totalDoses: med.totalDoses - 1);
    _logs.add(DoseLog(
      medicationId: med.id,
      medicationName: med.name,
      dose: med.dose,
      scheduled: dose.scheduled,
      takenAt: DateTime.now(),
    ));
    notifyListeners();
    return null;
  }

  // ---------------------------------------------------------------
  // Historial (RF-15)
  // ---------------------------------------------------------------

  /// Tomas confirmadas más las omitidas de hoy, de la más reciente a la
  /// más antigua.
  List<HistoryEntry> history(DateTime now) {
    final entries = <HistoryEntry>[
      for (final l in _logs)
        HistoryEntry(
          medicationName: l.medicationName,
          dose: l.dose,
          scheduled: l.scheduled,
          status: DoseStatus.taken,
        ),
      for (final d in dosesForDay(now))
        if (d.status == DoseStatus.missed)
          HistoryEntry(
            medicationName: d.medication.name,
            dose: d.medication.dose,
            scheduled: d.scheduled,
            status: DoseStatus.missed,
          ),
    ];
    entries.sort((a, b) => b.scheduled.compareTo(a.scheduled));
    return entries;
  }
}
