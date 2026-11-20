import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'emergency_lookup.dart';

/// Un escaneo hecho por el personal médico.
///
/// Solo guarda lo mínimo para identificar al paciente (nombre y tipo de
/// sangre) y el código leído. Los datos clínicos NO se copian al
/// historial: se consultan de nuevo con el código cada vez (RNF-01).
class ScanEntry {
  final String ownerId;
  final String name;
  final String bloodType;
  final String code;
  final DateTime scannedAt;

  const ScanEntry({
    required this.ownerId,
    required this.name,
    required this.bloodType,
    required this.code,
    required this.scannedAt,
  });

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'name': name,
        'bloodType': bloodType,
        'code': code,
        'scannedAt': scannedAt.toIso8601String(),
      };

  factory ScanEntry.fromJson(Map<String, dynamic> m) => ScanEntry(
        ownerId: m['ownerId'] as String,
        name: m['name'] as String,
        bloodType: m['bloodType'] as String,
        code: m['code'] as String,
        scannedAt: DateTime.parse(m['scannedAt'] as String),
      );
}

/// Paciente que el personal médico ya escaneó (para la lista de
/// «Pacientes registrados»).
class ScannedPatient {
  final ScanEntry last;
  final int scans;

  const ScannedPatient({required this.last, required this.scans});
}

/// Historial de escaneos de un usuario de personal médico, guardado en el
/// dispositivo (igual que `PatientStore`).
class ScanHistoryStore extends ChangeNotifier {
  ScanHistoryStore({required this.uid}) {
    _load();
  }

  final String uid;
  static const _prefix = 'kardex_scans_v1_';
  static const _maxEntries = 100;

  final List<ScanEntry> _entries = []; // más reciente primero
  bool _disposed = false;

  String get _key => '$_prefix$uid';

  List<ScanEntry> get entries => List.unmodifiable(_entries);

  /// Pacientes distintos, el escaneado más recientemente primero.
  List<ScannedPatient> get patients {
    final seen = <String>{};
    final result = <ScannedPatient>[];
    for (final e in _entries) {
      if (!seen.add(e.ownerId)) continue;
      final count = _entries.where((x) => x.ownerId == e.ownerId).length;
      result.add(ScannedPatient(last: e, scans: count));
    }
    return result;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      _entries
        ..clear()
        ..addAll(list
            .map((e) => ScanEntry.fromJson(Map<String, dynamic>.from(e as Map))));
      if (!_disposed) notifyListeners();
    } catch (_) {
      _entries.clear();
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(_entries.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      // Un fallo al guardar no debe romper la pantalla.
    }
  }

  /// Registra un escaneo válido.
  void add(EmergencyInfo info) {
    _entries.insert(
      0,
      ScanEntry(
        ownerId: info.ownerId,
        name: info.fullName.isEmpty ? 'Paciente sin nombre' : info.fullName,
        bloodType: info.bloodType,
        code: info.code,
        scannedAt: DateTime.now(),
      ),
    );
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    _save();
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    _save();
    notifyListeners();
  }
}
