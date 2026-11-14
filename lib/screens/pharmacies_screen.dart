import 'package:flutter/material.dart';

import '../core/validators.dart';
import '../services/pharmacy_geofencing.dart';
import '../services/pharmacy_store.dart';

/// Farmacias que se vigilan (RF-16): lista con nombre, dirección,
/// coordenadas y radio de detección. Se pueden agregar y quitar.
class PharmaciesScreen extends StatelessWidget {
  const PharmaciesScreen({super.key});

  Future<void> _confirmRemove(BuildContext context, Pharmacy p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar farmacia'),
        content: Text('¿Quitar "${p.name}" de la lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (ok == true) PharmacyStore.instance.remove(p.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = PharmacyStore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Farmacias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddPharmacyScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Agregar farmacia'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final items = store.pharmacies;
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No hay farmacias. Agrega una para recibir avisos '
                    'cuando estés cerca y te quede poco de un medicamento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                for (final p in items)
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.local_pharmacy_outlined),
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.address.isEmpty ? 'Sin dirección' : p.address}\n'
                        '${p.latitude.toStringAsFixed(5)}, '
                        '${p.longitude.toStringAsFixed(5)} · '
                        'radio ${p.radiusMeters.round()} m',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Quitar',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmRemove(context, p),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Formulario para agregar una farmacia con sus coordenadas (RF-16).
class AddPharmacyScreen extends StatefulWidget {
  const AddPharmacyScreen({super.key});

  @override
  State<AddPharmacyScreen> createState() => _AddPharmacyScreenState();
}

class _AddPharmacyScreenState extends State<AddPharmacyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _radius =
      TextEditingController(text: kDefaultPharmacyRadius.round().toString());
  bool _locating = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    _radius.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Llena la latitud y la longitud con la ubicación actual del teléfono:
  /// sirve cuando estás parado frente a la farmacia.
  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final pos = await PharmacyGeofencing().getCurrentPosition();
      _lat.text = pos.latitude.toStringAsFixed(6);
      _lng.text = pos.longitude.toStringAsFixed(6);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => _locating = false);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    PharmacyStore.instance.add(
      name: _name.text,
      address: _address.text,
      latitude: double.parse(_lat.text.trim().replaceAll(',', '.')),
      longitude: double.parse(_lng.text.trim().replaceAll(',', '.')),
      radiusMeters: double.parse(_radius.text.trim()),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Farmacia agregada')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar farmacia')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la farmacia',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.pharmacyName,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Dirección (opcional)',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.pharmacyAddress,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _locating ? null : _useMyLocation,
                icon: const Icon(Icons.my_location),
                label: Text(_locating
                    ? 'Buscando ubicación…'
                    : 'Usar mi ubicación actual'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _lat,
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Latitud',
                  hintText: '3.4516',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.latitude,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _lng,
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Longitud',
                  hintText: '-76.5320',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.longitude,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _radius,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Radio de detección (metros)',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.radiusMeters,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: const Text('Guardar farmacia'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
