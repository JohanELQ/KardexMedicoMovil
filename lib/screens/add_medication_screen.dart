import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/validators.dart';
import '../models/medication.dart';
import '../services/patient_store.dart';

/// Agregar o editar un medicamento (mockup 14, RF-10 y RF-21).
///
/// Se elige la frecuencia (1 a 4 tomas al día) y la hora de la primera
/// toma; los demás horarios se calculan repartiendo las tomas en las 24
/// horas. Los horarios se guardan en formato de 24 horas.
class AddMedicationScreen extends StatefulWidget {
  final PatientStore store;
  final Medication? existing; // si no es null, se está editando

  const AddMedicationScreen({super.key, required this.store, this.existing});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();

  int _perDay = 1;
  late TimeOfDay _firstTime;

  bool get _isEditing => widget.existing != null;

  static const _frequencies = <int, String>{
    1: '1 vez al día',
    2: '2 veces al día',
    3: '3 veces al día',
    4: '4 veces al día',
  };

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    if (m != null) {
      _nameCtrl.text = m.name;
      _doseCtrl.text = m.dose;
      _totalCtrl.text = m.totalDoses.toString();
      _perDay = m.times.length.clamp(1, 4).toInt();
      final p = parseHm(m.times.first);
      _firstTime = TimeOfDay(hour: p[0], minute: p[1]);
    } else {
      // Por defecto, la próxima hora en punto.
      final now = DateTime.now();
      _firstTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  /// Reparte las tomas del día a partir de la hora de la primera.
  List<String> _generateTimes() {
    final interval = 24 ~/ _perDay; // 24, 12, 8 o 6 horas
    final start = _firstTime.hour * 60 + _firstTime.minute;
    final list = <String>[];
    for (var k = 0; k < _perDay; k++) {
      final minutes = (start + k * interval * 60) % 1440;
      list.add(formatHm(minutes ~/ 60, minutes % 60));
    }
    list.sort();
    return list;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _firstTime,
    );
    if (picked != null) setState(() => _firstTime = picked);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final times = _generateTimes();
    final total = int.parse(_totalCtrl.text.trim());

    if (_isEditing) {
      widget.store.updateMedication(
        id: widget.existing!.id,
        name: _nameCtrl.text,
        dose: _doseCtrl.text,
        times: times,
        totalDoses: total,
      );
    } else {
      widget.store.addMedication(
        name: _nameCtrl.text,
        dose: _doseCtrl.text,
        times: times,
        totalDoses: total,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? 'Medicamento actualizado'
            : 'Medicamento agregado'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _generateTimes().map(formatHm12).join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar medicamento' : 'Agregar medicamento'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Nombre del medicamento'),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _decoration('Ej. Paracetamol'),
                  validator: Validators.medicationName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _label('Dosis'),
                TextFormField(
                  controller: _doseCtrl,
                  decoration: _decoration('Ej. 500 mg'),
                  validator: Validators.dose,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _label('Frecuencia'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in _frequencies.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _perDay == entry.key,
                        onSelected: (_) =>
                            setState(() => _perDay = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _label('Hora de la primera toma'),
                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(formatTime12(_firstTime.hour, _firstTime.minute)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Horarios: $schedule',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 16),
                _label('Dosis disponibles en el frasco o caja'),
                TextFormField(
                  controller: _totalCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration('Ej. 30'),
                  validator: Validators.totalDoses,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(_isEditing ? 'Guardar cambios' : 'Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
