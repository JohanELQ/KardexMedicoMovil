import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/patient_store.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'medical_profile_screen.dart';
import 'qr_screen.dart';

/// Pestaña "Perfil" del paciente (mockup 16): accesos al perfil médico,
/// al código QR y al historial, y cierre de sesión (RF-20).
class ProfileTab extends StatelessWidget {
  final AppUser user;
  final PatientStore store;
  final AuthService authService;

  const ProfileTab({
    super.key,
    required this.user,
    required this.store,
    required this.authService,
  });

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// RF-20: vuelve al inicio de sesión sin cerrar la app.
  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(authService: authService),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
              child: const Icon(Icons.person, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nameFromEmail(user.email),
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(user.email, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _item(
          context,
          Icons.medical_information_outlined,
          'Perfil médico',
          () => _open(context, MedicalProfileScreen(store: store, user: user)),
        ),
        _item(
          context,
          Icons.qr_code_2,
          'Código QR de emergencia',
          () => _open(context, QrScreen(store: store, user: user)),
        ),
        _item(
          context,
          Icons.history,
          'Historial de tomas',
          () => _open(context, HistoryScreen(store: store)),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey[400]),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
