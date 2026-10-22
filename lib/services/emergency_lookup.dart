import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'patient_store.dart';

/// Medicamento tal como lo ve el personal médico (RF-09).
class EmergencyMedication {
  final String name;
  final String dose;
  final List<String> times; // 'HH:mm' en 24 horas

  const EmergencyMedication({
    required this.name,
    required this.dose,
    required this.times,
  });
}

/// Información crítica de un paciente, solo lectura (RF-08).
///
/// Es una copia de los datos: no hay forma de modificar el perfil del
/// paciente desde aquí.
class EmergencyInfo {
  /// Identificador opaco del paciente y código leído (sirven para el
  /// historial de escaneos del personal médico).
  final String ownerId;
  final String code;
  final String fullName;
  final int? age;
  final String bloodType;
  final String allergies;
  final List<String> conditions;
  final String contactName;
  final String contactPhone;
  final List<EmergencyMedication> medications;

  const EmergencyInfo({
    required this.ownerId,
    required this.code,
    required this.fullName,
    required this.age,
    required this.bloodType,
    required this.allergies,
    required this.conditions,
    required this.contactName,
    required this.contactPhone,
    required this.medications,
  });
}

/// Busca el perfil que corresponde a un código QR (RF-07, RF-08).
///
/// Por ahora busca entre los pacientes guardados en este mismo
/// dispositivo. Cuando se conecte Firestore (o una base compartida), solo
/// cambia el interior de [find]: el QR ya lleva un identificador opaco
/// y la pantalla no necesita cambios.
class EmergencyLookup {
  EmergencyLookup._();

  static final RegExp _codeRegex =
      RegExp('${PatientStore.qrPrefix}:[A-Za-z0-9]+:[A-Za-z0-9]+');

  /// Saca el código de un texto cualquiera (sirve tanto para lo que lee
  /// la cámara como para el texto que copia el botón "Compartir").
  static String? extractCode(String raw) =>
      _codeRegex.firstMatch(raw)?.group(0);

  /// Devuelve la información del paciente, o null si el código no es
  /// legible, no existe, o es de una versión anterior del QR (RF-06: al
  /// actualizar el perfil, el código viejo deja de ser válido).
  static Future<EmergencyInfo?> find(String raw) async {
    final code = extractCode(raw);
    if (code == null) return null;
    final parts = code.split(':');
    if (parts.length != 3) return null;
    final ownerId = parts[1];
    final token = parts[2];

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(PatientStore.storagePrefix)) continue;
        final uid = key.substring(PatientStore.storagePrefix.length);
        if (PatientStore.ownerIdFor(uid) != ownerId) continue;

        final raw = prefs.getString(key);
        if (raw == null) return null;
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['qrToken'] != token) return null; // QR desactualizado
        final p = data['profile'];
        if (p == null) return null;

        final pm = Map<String, dynamic>.from(p as Map);
        final cm = Map<String, dynamic>.from(pm['contact'] as Map);
        final conditions = ((pm['conditions'] ?? '') as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final meds = (data['medications'] as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return EmergencyMedication(
            name: m['name'] as String,
            dose: m['dose'] as String,
            times: List<String>.from(m['times'] as List),
          );
        }).toList();

        return EmergencyInfo(
          ownerId: ownerId,
          code: code,
          fullName: ((pm['fullName'] ?? '') as String).trim(),
          age: pm['age'] as int?,
          bloodType: pm['bloodType'] as String,
          allergies: ((pm['allergies'] ?? '') as String).trim(),
          conditions: conditions,
          contactName: cm['fullName'] as String,
          contactPhone: cm['phone'] as String,
          medications: meds,
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
