import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/pharmacies.dart';
import 'notification_store.dart';
import 'patient_store.dart';
import 'pharmacy_geofencing.dart';
import 'system_notifications.dart';

/// Geofencing en segundo plano (RF-17, RNF-05, RNF-07).
///
/// Registra cada farmacia en la Geofencing API de Google Play Services.
/// Es el propio sistema quien vigila la zona con muy poco consumo de
/// batería, y despierta a la app cuando el paciente entra al radio de una
/// farmacia, aunque la app esté en segundo plano o cerrada. No hay GPS
/// encendido todo el tiempo.
///
/// Solo funciona en Android. En el navegador y en otras plataformas las
/// llamadas se ignoran sin dar error (allí sigue la revisión con la app
/// abierta de [PharmacyGeofencing]).

/// Cuenta que tiene la sesión abierta: la lee el aviso en segundo plano.
const String kActiveUidKey = 'kardex_active_uid_v1';

class BackgroundGeofencing {
  BackgroundGeofencing._();

  static final BackgroundGeofencing instance = BackgroundGeofencing._();

  bool _initialized = false;
  bool _busy = false;
  bool _again = false;
  bool _active = false;

  String? _uid;
  bool _enabled = false;
  List<Pharmacy> _pharmacies = const [];

  /// true si las farmacias están registradas en el sistema ahora mismo.
  bool get active => _active;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Pide los permisos de ubicación, incluido «Permitir todo el tiempo»,
  /// que Android exige para vigilar con la app cerrada. Devuelve true si
  /// quedó concedido.
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    try {
      var status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) return false;
      status = await Permission.locationAlways.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasBackgroundPermission() async {
    if (!_supported) return false;
    try {
      return await Permission.locationAlways.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Deja registradas en el sistema las farmacias de [pharmacies] si los
  /// avisos están activados [enabled] y hay permiso. Si no, las quita.
  Future<void> sync({
    required String uid,
    required bool enabled,
    required List<Pharmacy> pharmacies,
  }) async {
    if (!_supported) return;
    _uid = uid;
    _enabled = enabled;
    _pharmacies = pharmacies;
    if (_busy) {
      _again = true;
      return;
    }
    _busy = true;
    try {
      do {
        _again = false;
        await _apply();
      } while (_again);
    } catch (_) {
      _active = false;
    } finally {
      _busy = false;
    }
  }

  /// Repite el último [sync] (por ejemplo, al volver de los ajustes del
  /// celular después de conceder el permiso).
  Future<void> resync() async {
    final uid = _uid;
    if (uid == null) return;
    await sync(uid: uid, enabled: _enabled, pharmacies: _pharmacies);
  }

  Future<void> _apply() async {
    final uid = _uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kActiveUidKey, uid);

    if (!_initialized) {
      await NativeGeofenceManager.instance.initialize();
      _initialized = true;
    }
    await NativeGeofenceManager.instance.removeAllGeofences();
    _active = false;

    if (!_enabled || _pharmacies.isEmpty) return;
    if (!await hasBackgroundPermission()) return;

    for (final p in _pharmacies) {
      try {
        await NativeGeofenceManager.instance.createGeofence(
          Geofence(
            id: p.id,
            location: Location(latitude: p.latitude, longitude: p.longitude),
            // Android no vigila radios muy pequeños de forma fiable.
            radiusMeters: p.radiusMeters < 100 ? 100 : p.radiusMeters,
            triggers: {GeofenceEvent.enter},
            iosSettings: IosGeofenceSettings(initialTrigger: true),
            androidSettings: AndroidGeofenceSettings(
              initialTriggers: {GeofenceEvent.enter},
            ),
          ),
          pharmacyGeofenceTriggered,
        );
        _active = true;
      } on NativeGeofenceException {
        // Una farmacia que no se pudo registrar no impide las demás.
      }
    }
  }

  /// Quita todo (al cerrar sesión): los avisos son de esta cuenta.
  Future<void> stop() async {
    if (!_supported) return;
    _uid = null;
    _enabled = false;
    _active = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kActiveUidKey);
      if (!_initialized) {
        await NativeGeofenceManager.instance.initialize();
        _initialized = true;
      }
      await NativeGeofenceManager.instance.removeAllGeofences();
    } catch (_) {}
  }

  // ---------------------------------------------------------------
  // Lo que ocurre cuando el sistema avisa que se entró a una farmacia.
  // Corre en segundo plano, con la app cerrada, así que lee todo
  // directamente de lo guardado en el dispositivo.
  // ---------------------------------------------------------------

  static Future<void> handleEnter(List<String> pharmacyIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final uid = prefs.getString(kActiveUidKey);
    if (uid == null) return;

    // Avisos activados y umbral de días (RF-14, RF-18).
    final notif = _decode(prefs.getString('kardex_notifs_v1_$uid'));
    if (notif['pharmacyAlerts'] != true) return;
    final threshold =
        (notif['threshold'] ?? NotificationStore.defaultThreshold) as int;

    // Medicamentos que se están acabando.
    final patient =
        _decode(prefs.getString('${PatientStore.storagePrefix}$uid'));
    final low = <String>[];
    for (final e in (patient['medications'] ?? const []) as List) {
      final m = Map<String, dynamic>.from(e as Map);
      final perDay = (m['times'] as List).length;
      final total = m['totalDoses'] as int;
      final days = (perDay == 0 || total <= 0) ? 0 : total ~/ perDay;
      if (days <= threshold) low.add(m['name'] as String);
    }
    if (low.isEmpty) return;

    final pharmacies = _loadPharmacies(prefs);
    final geofencing = PharmacyGeofencing();

    for (final id in pharmacyIds) {
      final matches = pharmacies.where((p) => p.id == id);
      if (matches.isEmpty) continue;
      final pharmacy = matches.first;
      // RF-18: como máximo un aviso por farmacia cada 24 horas.
      if (!await geofencing.claimNotification(pharmacy.id)) continue;

      final body = pharmacyAlertBody(pharmacy, low);
      await NotificationStore.addFor(uid, 'Farmacia cerca', body);
      await SystemNotifications.instance.showPharmacyAlert(body);
    }
  }

  static List<Pharmacy> _loadPharmacies(SharedPreferences prefs) {
    try {
      final raw = prefs.getString('kardex_pharmacies_v1');
      if (raw == null || raw.isEmpty) return kDefaultPharmacies;
      return (jsonDecode(raw) as List)
          .map((e) => Pharmacy.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return kDefaultPharmacies;
    }
  }

  static Map<String, dynamic> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }
}

/// Se ejecuta cuando el sistema detecta una entrada a una farmacia. Tiene
/// que ser una función global, no un método.
@pragma('vm:entry-point')
Future<void> pharmacyGeofenceTriggered(GeofenceCallbackParams params) async {
  DartPluginRegistrant.ensureInitialized();
  if (params.event != GeofenceEvent.enter) return;
  try {
    await BackgroundGeofencing.handleEnter(
      [for (final g in params.geofences) g.id],
    );
  } catch (_) {
    // Un fallo aquí no debe tumbar el servicio en segundo plano.
  }
}
