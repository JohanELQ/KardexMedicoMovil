import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/medication.dart';
import '../services/patient_store.dart';
import 'add_medication_screen.dart';

/// Pestaña "Medicamentos" (mockup 13): lista de medicamentos con sus
/// horarios, dosis disponibles y días de tratamiento restantes (RF-13),
/// confirmación de toma (RF-12) y edición/eliminación (RF-21).
class MedicationsTab extends StatelessWidget {
  final PatientStore store;

  const MedicationsTab({super.key, required this.store});

  void _add(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddMedicationScreen(store: store)),
    );
  }

  void _edit(BuildContext context, Medication med) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(store: store, existing: med),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Medication med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar medicamento'),
        content: Text(
          '¿Seguro que quieres eliminar ${med.name}? También se dejarán '
          'de programar sus tomas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      store.deleteMedication(med.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${med.name} eliminado')),
        );
      }
    }
  }

  void _confirmTake(BuildContext context, Medication med) {
    final next = store.nextPendingFor(med.id, DateTime.now());
    if (next == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay tomas pendientes de este medicamento hoy'),
        ),
      );
      return;
    }
    final error = store.confirmDose(next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Toma confirmada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final meds = store.medications;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Medicamentos',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            Expanded(
              child: meds.isEmpty
                  ? _empty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      children: [
                        for (final m in meds) _medCard(context, m),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _add(context),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Agregar medicamento'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medication_outlined,
                  size: 64, color: Colors.grey[500]),
              const SizedBox(height: 12),
              const Text('Sin medicamentos registrados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Agrega el primero para recibir tus recordatorios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );

  Widget _medCard(BuildContext context, Medication m) {
    final lowStock = m.daysRemaining <= 3;
    final schedule = m.times.map(formatHm12).join(' · ');
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: Colors.blueGrey[400]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${m.name} · ${m.dose}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _edit(context, m);
                    if (value == 'delete') _delete(context, m);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 34, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schedule, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  Text(
                    '${daysRemainingText(m.daysRemaining)} · '
                    '${m.totalDoses} ${m.totalDoses == 1 ? "dosis disponible" : "dosis disponibles"}',
                    style: TextStyle(
                      color: lowStock ? Colors.red[700] : Colors.green[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _confirmTake(context, m),
                      child: const Text('Confirmar toma'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
