import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/format.dart';
import '../models/app_user.dart';
import '../models/medication.dart';

/// Datos del paciente: perfil médico, medicamentos e historial de tomas.
///
/// Se guardan en el dispositivo con `shared_preferences` (una entrada
/// por usuario), así que siguen ahí al cerrar y volver a abrir la app.
/// Cuando se conecte `sqflite` (RNF-02) o Firestore, solo hay que
/// cambiar el interior de `_load` y `_save`: las pantallas no cambian.
class PatientStore extends ChangeNotifier {
  PatientStore({required this.uid}) {
    _load();
  }

  final String uid;

  MedicalProfile? _profile;
  String? _qrToken;
  final List<Medication> _medications = [];
  final List<DoseLog> _logs = [];
  int _nextId = 1;
  bool _disposed = false;

  String get _storageKey => 'kardex_patient_v1_$uid';

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Guardado y carga en el dispositivo
  // ---------------------------------------------------------------

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;

      final p = data['profile'];
      if (p != null) {
        final pm = Map<String, dynamic>.from(p as Map);
        final cm = Map<String, dynamic>.from(pm['contact'] as Map);
        _profile = MedicalProfile(
          fullName: (pm['fullName'] ?? '') as String,
          age: pm['age'] as int?,
          bloodType: pm['bloodType'] as String,
          allergies: (pm['allergies'] ?? '') as String,
          conditions: (pm['conditions'] ?? '') as String,
          emergencyContact: EmergencyContact(
            fullName: cm['fullName'] as String,
            phone: cm['phone'] as String,
          ),
        );
      }
      _qrToken = data['qrToken'] as String?;
      _nextId = (data['nextId'] ?? 1) as int;

      _medications
        ..clear()
        ..addAll((data['medications'] as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return Medication(
            id: m['id'] as String,
            name: m['name'] as String,
            dose: m['dose'] as String,
            times: List<String>.from(m['times'] as List),
            totalDoses: m['totalDoses'] as int,
            createdAt: DateTime.parse(m['createdAt'] as String),
          );
        }));

      _logs
        ..clear()
        ..addAll((data['logs'] as List).map((e) {
          final l = Map<String, dynamic>.from(e as Map);
          return DoseLog(
            medicationId: l['medicationId'] as String,
            medicationName: l['medicationName'] as String,
            dose: l['dose'] as String,
            scheduled: DateTime.parse(l['scheduled'] as String),
            takenAt: DateTime.parse(l['takenAt'] as String),
          );
        }));

      if (!_disposed) notifyListeners();
    } catch (_) {
      // Si lo guardado está dañado, se empieza con datos vacíos.
      _profile = null;
      _qrToken = null;
      _medications.clear();
      _logs.clear();
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final p = _profile;
      final data = <String, dynamic>{
        'profile': p == null
            ? null
            : {
                'fullName': p.fullName,
                'age': p.age,
                'bloodType': p.bloodType,
                'allergies': p.allergies,
                'conditions': p.conditions,
                'contact': {
                  'fullName': p.emergencyContact.fullName,
                  'phone': p.emergencyContact.phone,
                },
              },
        'qrToken': _qrToken,
        'nextId': _nextId,
        'medications': [
          for (final m in _medications)
            {
              'id': m.id,
              'name': m.name,
              'dose': m.dose,
              'times': m.times,
              'totalDoses': m.totalDoses,
              'createdAt': m.createdAt.toIso8601String(),
            },
        ],
        'logs': [
          for (final l in _logs)
            {
              'medicationId': l.medicationId,
              'medicationName': l.medicationName,
              'dose': l.dose,
              'scheduled': l.scheduled.toIso8601String(),
              'takenAt': l.takenAt.toIso8601String(),
            },
        ],
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (_) {
      // Un fallo al guardar no debe romper la pantalla.
    }
  }

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
    _save();
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
    _save();
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
    _save();
    notifyListeners();
  }

  void deleteMedication(String id) {
    _medications.removeWhere((m) => m.id == id);
    _save();
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
    _save();
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
