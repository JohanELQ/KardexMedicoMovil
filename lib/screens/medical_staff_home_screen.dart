import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'scan_patient_qr_screen.dart';

/// Pantalla de inicio del personal médico (mockup 6, RF-03).
///
/// El botón "Escanear código QR" y los accesos rápidos quedan listos
/// para conectarse con mobile_scanner en RF-07; por ahora muestran un
/// aviso de que esa parte todavía no está implementada.
class MedicalStaffHomeScreen extends StatefulWidget {
  final AppUser user;
  final AuthService authService;

  const MedicalStaffHomeScreen({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<MedicalStaffHomeScreen> createState() =>
      _MedicalStaffHomeScreenState();
}

class _MedicalStaffHomeScreenState extends State<MedicalStaffHomeScreen> {
  int _tabIndex = 0;

  String get _displayName {
    if (widget.user.fullName.trim().isNotEmpty) {
      return widget.user.fullName.trim();
    }
    final at = widget.user.email.indexOf('@');
    return at > 0 ? widget.user.email.substring(0, at) : widget.user.email;
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanPatientQrScreen()),
    );
  }

  void _notAvailableYet(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature todavía no está disponible')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
              child: const Icon(Icons.medical_services_outlined),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, $_displayName',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const Text('Personal médico',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => _notAvailableYet('Las notificaciones'),
          ),
          // RF-20: cierre de sesión visible desde la pantalla principal.
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) =>
                    LoginScreen(authService: widget.authService),
              ),
              (route) => false,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _scanCard(context),
            const SizedBox(height: 24),
            const Text('Accesos rápidos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _quickAccessItem(Icons.people_outline, 'Pacientes registrados'),
            _quickAccessItem(Icons.history, 'Historial de escaneos'),
            _quickAccessItem(Icons.notifications_outlined, 'Notificaciones'),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);
          if (i != 0) _notAvailableYet('Esta sección');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.people_outline), label: 'Pacientes'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _scanCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openScanner,
        child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Escanear código QR',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text(
                    'Accede al perfil médico del paciente.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.qr_code_scanner,
                    color: Theme.of(context).colorScheme.primary),
                onPressed: _openScanner,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _quickAccessItem(IconData icon, String label) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey[400]),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _notAvailableYet(label),
      ),
    );
  }
}
