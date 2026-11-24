import 'package:flutter/material.dart';

import '../core/format.dart';
import '../services/scan_history_store.dart';
import 'scan_history_screen.dart';

/// Pestaña «Pacientes» del personal médico: los pacientes distintos que
/// ya escaneó, con la fecha del último escaneo.
class StaffPatientsTab extends StatelessWidget {
  final ScanHistoryStore history;

  const StaffPatientsTab({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: history,
      builder: (context, _) {
        final patients = history.patients;
        final now = DateTime.now();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Pacientes registrados',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Pacientes cuyo código QR ya escaneaste.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (patients.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Column(
                  children: [
                    Icon(Icons.people_outline,
                        size: 64, color: Colors.grey[500]),
                    const SizedBox(height: 16),
                    const Text('Todavía no hay pacientes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      'Escanea un código QR para que aparezca aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              for (final p in patients)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.12),
                      child: Icon(Icons.person_outline,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(p.last.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Sangre ${p.last.bloodType} · Último escaneo: '
                      '${dayLabel(p.last.scannedAt, now)} · '
                      '${p.scans} ${p.scans == 1 ? "escaneo" : "escaneos"}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => reopenScan(context, p.last),
                  ),
                ),
          ],
        );
      },
    );
  }
}
