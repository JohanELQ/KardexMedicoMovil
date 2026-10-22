import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/medication.dart';
import '../services/patient_store.dart';

/// Minutos que se pospone un recordatorio al tocar «Posponer».
const int kSnoozeMinutes = 10;

/// Recordatorio de toma a pantalla completa (mockup 10, RF-11).
///
/// Muestra el nombre y la dosis, con las acciones «Confirmar» y
/// «Posponer». Por ahora aparece mientras la app está abierta; las
/// notificaciones con la app cerrada llegan con flutter_local_notifications
/// en Android.
Future<void> showMedicationReminder({
  required BuildContext context,
  required PatientStore store,
  required ScheduledDose dose,
}) {
  final messenger = ScaffoldMessenger.of(context);

  void confirm(BuildContext dialogContext) {
    final error = store.confirmDose(dose);
    Navigator.of(dialogContext).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Toma de ${dose.medication.name} confirmada'),
      ),
    );
  }

  void snooze(BuildContext dialogContext) {
    store.snooze(dose, const Duration(minutes: kSnoozeMinutes));
    Navigator.of(dialogContext).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Te lo recordamos de nuevo en $kSnoozeMinutes minutos',
        ),
      ),
    );
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Recordatorio de medicamento',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return PopScope(
        canPop: false,
        child: _ReminderOverlay(
          dose: dose,
          onConfirm: () => confirm(dialogContext),
          onSnooze: () => snooze(dialogContext),
        ),
      );
    },
  );
}

class _ReminderOverlay extends StatelessWidget {
  final ScheduledDose dose;
  final VoidCallback onConfirm;
  final VoidCallback onSnooze;

  const _ReminderOverlay({
    required this.dose,
    required this.onConfirm,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final med = dose.medication;
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2F4C7E), Color(0xFF7C6FB0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 56),
                Text(
                  formatHm(dose.scheduled.hour, dose.scheduled.minute),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 76,
                    fontWeight: FontWeight.w300,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateShortEs(dose.scheduled),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: primary,
                            child: const Icon(Icons.favorite,
                                size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Kardex',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          // La X equivale a posponer: así la toma no se
                          // olvida sin querer.
                          IconButton(
                            tooltip: 'Posponer',
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: onSnooze,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Recordatorio de medicamento',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        'Es hora de tomar ${med.name} ${med.dose}.',
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onConfirm,
                          child: const Text('Confirmar'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onSnooze,
                          child: const Text('Posponer'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
