import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permisos del dispositivo (mockup 17, RF-22): muestra el estado de
/// cámara, ubicación y notificaciones, y permite activarlos o abrir los
/// ajustes del celular para cambiarlos.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionInfo {
  final Permission permission;
  final IconData icon;
  final String title;
  final String description;

  const _PermissionInfo(
      this.permission, this.icon, this.title, this.description);
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  static final List<_PermissionInfo> _items = [
    _PermissionInfo(
      Permission.camera,
      Icons.photo_camera_outlined,
      'Cámara',
      'Necesaria para escanear códigos QR.',
    ),
    _PermissionInfo(
      Permission.locationWhenInUse,
      Icons.location_on_outlined,
      'Ubicación',
      'Necesaria para avisarte cuando estés cerca de una farmacia.',
    ),
    _PermissionInfo(
      Permission.notification,
      Icons.notifications_outlined,
      'Notificaciones',
      'Necesarias para los recordatorios de tus medicamentos.',
    ),
  ];

  final Map<Permission, PermissionStatus> _status = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver de los ajustes del celular se vuelve a leer el estado.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (kIsWeb) return;
    for (final item in _items) {
      try {
        _status[item.permission] = await item.permission.status;
      } catch (_) {
        // Permiso no disponible en esta plataforma.
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggle(_PermissionInfo item, bool value) async {
    final current = _status[item.permission];
    // Una app no puede quitarse un permiso a sí misma, ni volver a pedir
    // uno bloqueado: en esos casos se abren los ajustes del celular.
    if (!value || (current?.isPermanentlyDenied ?? false)) {
      await openAppSettings();
      return;
    }
    try {
      _status[item.permission] = await item.permission.request();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permisos')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (kIsWeb)
              Card(
                elevation: 0,
                color: Colors.amber[50],
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Estás usando Kardex en el navegador. Aquí los permisos '
                    'se gestionan desde el candado que aparece junto a la '
                    'dirección de la página. En el celular esta pantalla '
                    'muestra y cambia cada permiso.',
                  ),
                ),
              )
            else
              for (final item in _items) _tile(item),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: const ListTile(
                leading: Icon(Icons.folder_outlined),
                title: Text('Almacenamiento'),
                subtitle: Text(
                  'Tus datos se guardan en el propio dispositivo para que '
                  'funcionen sin conexión. No necesita permiso.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Puedes gestionar los permisos desde la configuración de tu '
              'dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(_PermissionInfo item) {
    final granted = _status[item.permission]?.isGranted ?? false;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: SwitchListTile(
        secondary: Icon(item.icon),
        title: Text(item.title),
        subtitle: Text(item.description, style: const TextStyle(fontSize: 12)),
        value: granted,
        onChanged: (v) => _toggle(item, v),
      ),
    );
  }
}
