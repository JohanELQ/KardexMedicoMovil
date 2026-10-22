import 'package:flutter/material.dart';

import '../core/format.dart';
import '../services/emergency_lookup.dart';

/// Vista de emergencia que ve el personal médico tras un escaneo válido
/// (RF-08, RF-09).
///
/// Es de solo lectura: no hay botones para editar, eliminar ni agregar
/// datos del paciente, y el paciente no tuvo que desbloquear nada.
class EmergencyViewScreen extends StatelessWidget {
  final EmergencyInfo info;

  const EmergencyViewScreen({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final name =
        info.fullName.isEmpty ? 'Paciente sin nombre registrado' : info.fullName;
    final summary = <String>[
      if (info.age != null) 'Edad: ${info.age} años',
      'Tipo de sangre: ${info.bloodType}',
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(title: const Text('Información de emergencia')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solo lectura. No se puede modificar la información '
                      'del paciente.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: primary.withOpacity(0.15),
                child: Icon(Icons.person, size: 44, color: primary),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(summary,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 15)),
            ),
            const SizedBox(height: 24),
            _title('Alergias'),
            _card(
              icon: Icons.warning_amber_rounded,
              color: Colors.red,
              title: info.allergies.isEmpty
                  ? 'Ninguna registrada'
                  : info.allergies,
            ),
            const SizedBox(height: 20),
            _title('Condiciones médicas'),
            if (info.conditions.isEmpty)
              _card(
                icon: Icons.check_circle_outline,
                color: Colors.grey,
                title: 'Ninguna registrada',
              )
            else
              for (final c in info.conditions)
                _card(
                  icon: Icons.monitor_heart_outlined,
                  color: Colors.teal,
                  title: c,
                ),
            const SizedBox(height: 20),
            // RF-09: lista completa de medicamentos o mensaje explícito.
            _title('Medicamentos actuales'),
            if (info.medications.isEmpty)
              _card(
                icon: Icons.medication_outlined,
                color: Colors.grey,
                title: 'Sin medicamentos registrados',
              )
            else
              for (final m in info.medications)
                _card(
                  icon: Icons.medication,
                  color: primary,
                  title: '${m.name} ${m.dose}',
                  subtitle: m.times.isEmpty
                      ? 'Sin horarios'
                      : 'Horarios: ${m.times.map(formatHm12).join(' · ')}',
                ),
            const SizedBox(height: 20),
            _title('Contacto de emergencia'),
            _card(
              icon: Icons.phone_in_talk_outlined,
              color: Colors.orange,
              title: info.contactName,
              subtitle: info.contactPhone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      );

  Widget _card({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
  }) =>
      Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(subtitle,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
