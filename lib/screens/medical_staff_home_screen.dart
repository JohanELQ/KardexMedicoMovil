import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/scan_history_store.dart';
import 'scan_history_screen.dart';
import 'scan_patient_qr_screen.dart';
import 'staff_patients_tab.dart';
import 'staff_profile_tab.dart';

/// Pantalla de inicio del personal médico (mockup 6, RF-03).
///
/// Tres pestañas: Inicio (escanear y accesos rápidos), Pacientes (los ya
/// escaneados) y Perfil (cuenta y cierre de sesión, RF-20). Todas comparten
/// el mismo [ScanHistoryStore].
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
  late final ScanHistoryStore _history =
      ScanHistoryStore(uid: widget.user.uid);
  int _tabIndex = 0;

  @override
  void dispose() {
    _history.dispose();
    super.dispose();
  }

  String get _displayName {
    if (widget.user.fullName.trim().isNotEmpty) {
      return widget.user.fullName.trim();
    }
    return nameFromEmail(widget.user.email);
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanPatientQrScreen(history: _history),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanHistoryScreen(history: _history),
      ),
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
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            _homeTab(context),
            StaffPatientsTab(history: _history),
            StaffProfileTab(
              user: widget.user,
              history: _history,
              authService: widget.authService,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Pacientes'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _homeTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
              child: const Icon(Icons.medical_services_outlined),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola, $_displayName',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const Text('Personal médico',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => _notAvailableYet('Las notificaciones'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _scanCard(context),
        const SizedBox(height: 24),
        const Text('Accesos rápidos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: _history,
          builder: (context, _) {
            final patients = _history.patients.length;
            final scans = _history.entries.length;
            return Column(
              children: [
                _quickAccessItem(
                  Icons.people_outline,
                  'Pacientes registrados',
                  subtitle: '$patients ${patients == 1 ? "paciente" : "pacientes"}',
                  onTap: () => setState(() => _tabIndex = 1),
                ),
                _quickAccessItem(
                  Icons.history,
                  'Historial de escaneos',
                  subtitle: '$scans ${scans == 1 ? "escaneo" : "escaneos"}',
                  onTap: _openHistory,
                ),
                _quickAccessItem(
                  Icons.notifications_outlined,
                  'Notificaciones',
                  onTap: () => _notAvailableYet('Las notificaciones'),
                ),
              ],
            );
          },
        ),
      ],
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Escanear código QR',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    SizedBox(height: 4),
                    Text(
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
                child: Icon(Icons.qr_code_scanner,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAccessItem(
    IconData icon,
    String label, {
    String? subtitle,
    required VoidCallback onTap,
  }) {
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
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
