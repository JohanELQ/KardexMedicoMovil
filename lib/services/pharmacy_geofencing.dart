import 'package:geolocator/geolocator.dart';

// Lógica de cercanía a farmacias escrita por JohanELQ (rama
// feature/Geofencing_drogeria). Aquí se integró con los medicamentos y las
// notificaciones de la app, y se ajustó el aviso para cumplir RF-18: no más
// de una vez por farmacia en 24 horas.

class Pharmacy {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const Pharmacy({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
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
  final double radiusMeters;

  // RF-18: cada farmacia avisa como máximo una vez cada 24 horas.
  final Map<String, DateTime> _lastNotified = {};

  PharmacyGeofencing({this.radiusMeters = 300});

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

  /// Farmacias dentro del radio de las que corresponde avisar ahora.
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

      if (distance > radiusMeters) continue;

      final last = _lastNotified[pharmacy.id];
      if (last == null || at.difference(last) >= const Duration(hours: 24)) {
        _lastNotified[pharmacy.id] = at;
        nearby.add(pharmacy);
      }
    }

    return nearby;
  }
}
