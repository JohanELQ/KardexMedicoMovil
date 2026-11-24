import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/pharmacies.dart';
import 'pharmacy_geofencing.dart';

/// Lista de farmacias que se vigilan (RF-16), guardada en el dispositivo.
///
/// Empieza con las farmacias semilla de [kDefaultPharmacies]; el paciente
/// puede agregar las suyas o quitar las que no quiera.
class PharmacyStore extends ChangeNotifier {
  PharmacyStore._() {
    _load();
  }

  /// Una sola lista compartida por toda la app.
  static final PharmacyStore instance = PharmacyStore._();

  static const _key = 'kardex_pharmacies_v1';

  List<Pharmacy> _items = List.of(kDefaultPharmacies);

  List<Pharmacy> get pharmacies => List.unmodifiable(_items);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      _items = (jsonDecode(raw) as List)
          .map((e) => Pharmacy.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    } catch (_) {
      _items = List.of(kDefaultPharmacies);
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(_items.map((p) => p.toJson()).toList()),
      );
    } catch (_) {
      // Un fallo al guardar no debe romper la pantalla.
    }
  }

  void add({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) {
    _items = [
      ..._items,
      Pharmacy(
        id: 'farmacia_${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        address: address.trim(),
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      ),
    ];
    _save();
    notifyListeners();
  }

  void remove(String id) {
    _items = _items.where((p) => p.id != id).toList();
    _save();
    notifyListeners();
  }
}
