import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

/// Farmacia registrada en el catálogo local/remoto de Kardex.
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

/// La alerta solo se activa cuando el usuario marcó el medicamento
/// como pendiente de reposición.
class NeededMedication {
  const NeededMedication({
    required this.name,
    required this.needsRefill,
  });

  final String name;
  final bool needsRefill;
}

class PharmacyGeofencing {
  PharmacyGeofencing({
    this.radiusMeters = 300,
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications =
            notifications ?? FlutterLocalNotificationsPlugin();

  final double radiusMeters;
  final FlutterLocalNotificationsPlugin _notifications;
  StreamSubscription<Position>? _positionSubscription;
  final Set<String> _insidePharmacies = <String>{};
  bool _initialized = false;

  Future<void> initializeNotifications() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
    );
    await _notifications.initialize(settings);
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Activa la ubicación del dispositivo para usar farmacias cercanas.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Kardex no tiene permiso para consultar la ubicación.');
    }

    // Esta implementación trabaja con la app abierta: no solicita
    // permiso de ubicación permanente/en segundo plano.
    return true;
  }

  /// Inicia comprobaciones mientras la aplicación permanece abierta.
  /// No utiliza Google Geofencing API ni funciona con la app cerrada.
  Future<void> startMonitoring({
    required List<Pharmacy> pharmacies,
    required List<NeededMedication> medications,
    required void Function(Pharmacy pharmacy) onNearbyPharmacy,
  }) async {
    await stopMonitoring();
    await initializeNotifications();
    await _ensureLocationPermission();

    final hasPendingRefill =
        medications.any((medication) => medication.needsRefill);
    if (!hasPendingRefill || pharmacies.isEmpty) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) async {
        for (final pharmacy in pharmacies) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            pharmacy.latitude,
            pharmacy.longitude,
          );

          if (distance <= radiusMeters) {
            // Solo notifica al entrar; no repite en cada actualización GPS.
            if (_insidePharmacies.add(pharmacy.id)) {
              onNearbyPharmacy(pharmacy);
              await _showPharmacyNotification(pharmacy);
            }
          } else {
            _insidePharmacies.remove(pharmacy.id);
          }
        }
      },
      onError: (Object error) {
        // El consumidor puede informar errores mediante su UI/log.
      },
    );
  }

  Future<void> _showPharmacyNotification(Pharmacy pharmacy) async {
    const android = AndroidNotificationDetails(
      'nearby_pharmacies',
      'Farmacias cercanas',
      channelDescription: 'Avisos de proximidad a farmacias por reposición',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: android,
      iOS: DarwinNotificationDetails(),
    );
    await _notifications.show(
      pharmacy.id.hashCode & 0x7fffffff,
      'Farmacia cercana',
      'Estás cerca de ${pharmacy.name}. Revisa tus medicamentos pendientes.',
      details,
    );
  }

  Future<void> stopMonitoring() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _insidePharmacies.clear();
  }

  /// Utilidad para comprobar una posición puntual, útil para pruebas.
  List<Pharmacy> findNearbyPharmacies({
    required Position userPosition,
    required List<Pharmacy> pharmacies,
    required List<NeededMedication> medications,
  }) {
    if (!medications.any((medication) => medication.needsRefill)) {
      return <Pharmacy>[];
    }

    return pharmacies.where((pharmacy) {
      final distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        pharmacy.latitude,
        pharmacy.longitude,
      );
      return distance <= radiusMeters;
    }).toList();
  }
}
