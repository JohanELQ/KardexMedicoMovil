//Agregar estos paquetes en la terminal
//flutter pub add geolocator
//flutter pub add flutter_local_notifications

import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

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

class PharmacyGeofencing {
  final double radiusMeters;

  // Evita repetir el aviso mientras el usuario
  // permanece dentro del mismo radio.
  final Set<String> _notifiedPharmacies = {};

  PharmacyGeofencing({this.radiusMeters = 300});

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

  List<Pharmacy> findNearbyPharmacies({
    required Position userPosition,
    required List<Pharmacy> pharmacies,
    required List<NeededMedication> medications,
  }) {
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

      if (distance <= radiusMeters) {
        if (_notifiedPharmacies.add(pharmacy.id)) {
          nearby.add(pharmacy);
        }
      } else {
        // Permite un nuevo aviso si sale y vuelve a entrar.
        _notifiedPharmacies.remove(pharmacy.id);
      }
    }

    return nearby;
  }
}
