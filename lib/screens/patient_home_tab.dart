import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/format.dart';
import '../models/app_user.dart';
import '../models/medication.dart';
import '../services/notification_store.dart';
import '../services/patient_store.dart';
import 'notifications_screen.dart';
import 'medical_profile_screen.dart';
import 'qr_screen.dart';

/// Pestaña "Inicio" del paciente (mockup 5): saludo, tarjeta del QR de
/// emergencia y próximas dosis de hoy con confirmación de toma.
class PatientHomeTab extends StatelessWidget {
  final AppUser user;
  final PatientStore store;
  final NotificationStore notifications;
  final VoidCallback onSeeMedications;

  const PatientHomeTab({
    super.key,
    required this.user,
    required this.store,
    required this.notifications,
    required this.onSeeMedications,
  });

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          store: notifications,
          showThreshold: true,
          patientStore: store,
        ),
      ),
    );
  }

  void _completeProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditMedicalProfileScreen(store: store)),
    );
  }

  void _openQr(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrScreen(store: store, user: user),
      ),
    );
  }

  void _confirm(BuildContext context, ScheduledDose dose) {
    final error = store.confirmDose(dose);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Toma confirmada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final doses = store.dosesForDay(DateTime.now());
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(context),
            const SizedBox(height: 16),
            _qrCard(context),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Próximas dosis',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: onSeeMedications,
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (doses.isEmpty)
              _emptyDoses()
            else
              for (final d in doses) _doseTile(context, d),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Row(
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
            Text('Hola, ${displayName(store.profile, user)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Text('Paciente',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const Spacer(),
        NotificationBell(
          store: notifications,
          onPressed: () => _openNotifications(context),
        ),
      ],
    );
  }

  Widget _qrCard(BuildContext context) {
    final qrData = store.qrData;
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
                  Text(
                    qrData == null
                        ? 'Completa tu perfil médico para generarlo'
                        : 'Muestra este código en caso de emergencia',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    onPressed: () => qrData == null
                        ? _completeProfile(context)
                        : _openQr(context),
                    child: Text(
                        qrData == null ? 'Completar perfil' : 'Ver código QR'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 82,
              height: 82,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: qrData == null
                  ? Icon(Icons.qr_code_2, size: 60, color: Colors.grey[400])
                  : QrImageView(data: qrData, size: 70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyDoses() => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No tienes tomas programadas para hoy. Agrega un medicamento '
            'en la pestaña Medicamentos.',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      );

  Widget _doseTile(BuildContext context, ScheduledDose d) {
    final IconData icon;
    final Color color;
    final String label;
    switch (d.status) {
      case DoseStatus.taken:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Confirmada';
      case DoseStatus.missed:
        icon = Icons.cancel_outlined;
        color = Colors.orange.shade800;
        label = 'Omitida';
      case DoseStatus.pending:
        icon = Icons.radio_button_unchecked;
        color = Colors.grey.shade500;
        label = 'Toca para confirmar';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Icon(Icons.medication, color: Colors.blueGrey[400]),
        title: Text('${d.medication.name} · ${d.medication.dose}'),
        subtitle: Text(
          'Hoy · ${formatTime12(d.scheduled.hour, d.scheduled.minute)}'
          ' · $label',
        ),
        trailing: Icon(icon, color: color),
        onTap: d.status == DoseStatus.pending
            ? () => _confirm(context, d)
            : null,
      ),
    );
  }
}
