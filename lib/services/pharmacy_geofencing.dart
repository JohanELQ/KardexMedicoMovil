import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Lógica de cercanía a farmacias escrita por JohanELQ (rama
// feature/Geofencing_drogeria). Aquí se integró con los medicamentos y las
// notificaciones de la app, y se ajustó el aviso para cumplir RF-18: no más
// de una vez por farmacia en 24 horas.

/// Radio de detección por defecto alrededor de una farmacia (RF-16).
const double kDefaultPharmacyRadius = 150;

/// Farmacia con nombre, dirección, coordenadas y radio de detección (RF-16).
class Pharmacy {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const Pharmacy({
    required this.id,
    required this.name,
    this.address = '',
    required this.latitude,
    required this.longitude,
    this.radiusMeters = kDefaultPharmacyRadius,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
      };

  factory Pharmacy.fromJson(Map<String, dynamic> m) => Pharmacy(
        id: m['id'] as String,
        name: m['name'] as String,
        address: (m['address'] ?? '') as String,
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        radiusMeters:
            ((m['radiusMeters'] ?? kDefaultPharmacyRadius) as num).toDouble(),
      );
}

class NeededMedication {
  final String name;
  final bool needsRefill;

  const NeededMedication({
    required this.name,
    required this.needsRefill,
  });
}

/// Texto del aviso de farmacia cercana (RF-18).
String pharmacyAlertBody(Pharmacy pharmacy, List<String> medicationNames) {
  final meds = medicationNames.isEmpty
      ? 'tus medicamentos'
      : medicationNames.join(', ');
  return 'Estás cerca de ${pharmacy.name}. Te queda poco de $meds.';
}

class PharmacyGeofencing {
  static const _historyKey = 'kardex_pharmacy_notified_v1';

  // RF-18: cada farmacia avisa como máximo una vez cada 24 horas. El
  // registro se guarda en el dispositivo para que sobreviva si se cierra
  // la app.
  final Map<String, DateTime> _lastNotified = {};

  /// Carga el registro de avisos ya hechos. Llamar una vez al iniciar.
  Future<void> loadHistory({bool reload = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (reload) await prefs.reload();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return;
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      for (final e in data.entries) {
        _lastNotified[e.key] = DateTime.parse(e.value as String);
      }
    } catch (_) {
      // Registro dañado: se empieza vacío.
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _historyKey,
        jsonEncode({
          for (final e in _lastNotified.entries)
            e.key: e.value.toIso8601String(),
        }),
      );
    } catch (_) {
      // Un fallo al guardar no debe romper el aviso.
    }
  }

  /// Usado por el aviso en segundo plano (RF-18): devuelve true y anota
  /// el aviso si esa farmacia no avisó en las últimas 24 horas. Vuelve a
  /// leer lo guardado porque la app abierta puede haber avisado antes.
  Future<bool> claimNotification(String pharmacyId, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    _lastNotified.clear();
    await loadHistory(reload: true);
    final last = _lastNotified[pharmacyId];
    if (last != null && at.difference(last) < const Duration(hours: 24)) {
      return false;
    }
    _lastNotified[pharmacyId] = at;
    await _saveHistory();
    return true;
  }

  /// Pide el permiso de ubicación si hace falta y devuelve la posición.
  /// Lanza una excepción con un mensaje legible si no se puede.
  Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw Exception('Activa el servicio de ubicación del dispositivo.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Kardex necesita permiso de ubicación.');
    }

    return Geolocator.getCurrentPosition();
  }

  /// Farmacias dentro de su radio de las que corresponde avisar ahora.
  List<Pharmacy> findNearbyPharmacies({
    required Position userPosition,
    required List<Pharmacy> pharmacies,
    required List<NeededMedication> medications,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final needsMedication =
        medications.any((medication) => medication.needsRefill);

    if (!needsMedication) return [];

    final nearby = <Pharmacy>[];

    for (final pharmacy in pharmacies) {
      final distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        pharmacy.latitude,
        pharmacy.longitude,
      );

      if (distance > pharmacy.radiusMeters) continue;

      final last = _lastNotified[pharmacy.id];
      if (last == null || at.difference(last) >= const Duration(hours: 24)) {
        _lastNotified[pharmacy.id] = at;
        nearby.add(pharmacy);
      }
    }

    if (nearby.isNotEmpty) _saveHistory();
    return nearby;
  }
}
