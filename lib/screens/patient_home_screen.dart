import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/app_user.dart';

/// Pantalla de inicio del paciente (mockup 5, RF-03).
///
/// El código QR y la lista de "próximas dosis" usan datos de ejemplo
/// por ahora: el QR real se genera en RF-06 a partir del perfil médico,
/// y la lista de dosis viene de los medicamentos registrados (RF-10 a
/// RF-13), que todavía no están implementados.
class PatientHomeScreen extends StatefulWidget {
  final AppUser user;

  const PatientHomeScreen({super.key, required this.user});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _tabIndex = 0;

  String get _displayName {
    if (widget.user.fullName.trim().isNotEmpty) {
      return widget.user.fullName.trim();
    }
    final at = widget.user.email.indexOf('@');
    return at > 0 ? widget.user.email.substring(0, at) : widget.user.email;
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
              child: const Icon(Icons.person),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, $_displayName',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const Text('Paciente',
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
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _emergencyQrCard(context),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Próximas dosis',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => _notAvailableYet('El listado completo'),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _doseItem('Paracetamol 500 mg', 'Hoy · 08:00 PM', done: true),
            _doseItem('Lisinopril 10 mg', 'Hoy · 02:00 PM', done: true),
            _doseItem('Metformina 850 mg', 'Hoy · 08:00 PM', done: false),
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
              icon: Icon(Icons.medication_outlined), label: 'Medicamentos'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _emergencyQrCard(BuildContext context) {
    final qrData = 'KARDEX-EMERGENCIA:${widget.user.uid}';
    return Card(
      color: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tu código QR de emergencia',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text(
                    'Muestra este código en caso de emergencia',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    onPressed: () => _notAvailableYet('La vista ampliada del QR'),
                    child: const Text('Ver código QR'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(data: qrData, size: 70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doseItem(String name, String schedule, {required bool done}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(Icons.medication, color: Colors.blueGrey[400]),
        title: Text(name),
        subtitle: Text(schedule),
        trailing: Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? Colors.green : Colors.grey[400],
        ),
      ),
    );
  }
}
