import 'package:flutter/material.dart';

import '../core/format.dart';
import '../services/emergency_lookup.dart';
import '../services/scan_history_store.dart';
import 'emergency_view_screen.dart';

/// Vuelve a abrir la ficha de un paciente escaneado antes.
///
/// Si el paciente actualizó su perfil, su QR cambió y el código guardado
/// ya no vale (RF-06): se pide escanear el nuevo.
Future<void> reopenScan(BuildContext context, ScanEntry entry) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final info = await EmergencyLookup.find(entry.code);
  if (info == null) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'El código de este paciente cambió o ya no existe. '
          'Escanea su QR de nuevo.',
        ),
      ),
    );
    return;
  }
  navigator.push(
    MaterialPageRoute(builder: (_) => EmergencyViewScreen(info: info)),
  );
}

/// Historial de escaneos del personal médico.
class ScanHistoryScreen extends StatelessWidget {
  final ScanHistoryStore history;

  const ScanHistoryScreen({super.key, required this.history});

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Borrar historial'),
        content: const Text(
          'Se borrarán todos los escaneos guardados en este dispositivo. '
          'Los perfiles de los pacientes no se modifican.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok == true) history.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: history,
      builder: (context, _) {
        final entries = history.entries;
        final now = DateTime.now();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Historial de escaneos'),
            actions: [
              if (entries.isNotEmpty)
                IconButton(
                  tooltip: 'Borrar historial',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmClear(context),
                ),
            ],
          ),
          body: entries.isEmpty
              ? const _Empty(
                  icon: Icons.history,
                  title: 'Aún no has escaneado ningún código',
                  subtitle: 'Cuando escanees un QR, aparecerá aquí.',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      if (i == 0 ||
                          dayLabel(entries[i].scannedAt, now) !=
                              dayLabel(entries[i - 1].scannedAt, now))
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(
                            dayLabel(entries[i].scannedAt, now),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      _EntryTile(
                        title: entries[i].name,
                        subtitle: 'Tipo de sangre ${entries[i].bloodType} · '
                            '${formatTime12(entries[i].scannedAt.hour, entries[i].scannedAt.minute)}',
                        onTap: () => reopenScan(context, entries[i]),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EntryTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.12),
          child: Icon(Icons.person_outline,
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Empty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
