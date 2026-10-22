import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/scan_history_store.dart';
import 'login_screen.dart';
import 'scan_history_screen.dart';

/// Pestaña «Perfil» del personal médico: datos de la cuenta, acceso al
/// historial y cierre de sesión (RF-20).
class StaffProfileTab extends StatelessWidget {
  final AppUser user;
  final ScanHistoryStore history;
  final AuthService authService;

  const StaffProfileTab({
    super.key,
    required this.user,
    required this.history,
    required this.authService,
  });

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
    final primary = Theme.of(context).colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: primary.withOpacity(0.15),
              child: Icon(Icons.medical_services_outlined,
                  size: 30, color: primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nameFromEmail(user.email),
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(user.email, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(user.role.label,
                      style: TextStyle(color: primary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _item(
          context,
          icon: Icons.history,
          label: 'Historial de escaneos',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScanHistoryScreen(history: history),
            ),
          ),
        ),
        _item(
          context,
          icon: Icons.logout,
          label: 'Cerrar sesión',
          color: Colors.red,
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.blueGrey[400]),
        title: Text(label, style: TextStyle(color: color)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
