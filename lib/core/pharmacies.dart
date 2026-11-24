import '../services/pharmacy_geofencing.dart';

/// Farmacias precargadas (datos semilla, RF-16). Es solo un ejemplo (la de
/// JohanELQ, en Cali): el paciente agrega las suyas desde
/// Notificaciones → Administrar farmacias.
const List<Pharmacy> kDefaultPharmacies = [
  Pharmacy(
    id: 'farmacia_001',
    name: 'Farmacia de ejemplo (Cali)',
    address: 'Cali, Valle del Cauca',
    latitude: 3.4516,
    longitude: -76.5320,
  ),
];
