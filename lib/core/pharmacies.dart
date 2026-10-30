import '../services/pharmacy_geofencing.dart';

/// Farmacias que se vigilan. Por ahora es una lista fija de ejemplo (la
/// de JohanELQ). Debe reemplazarse por una base de datos o un servicio
/// confiable con las ubicaciones reales.
const List<Pharmacy> kPharmacies = [
  Pharmacy(
    id: 'farmacia_001',
    name: 'Farmacia cercana',
    latitude: 3.4516,
    longitude: -76.5320,
  ),
];
