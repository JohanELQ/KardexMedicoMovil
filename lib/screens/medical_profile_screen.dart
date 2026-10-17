import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/validators.dart';
import '../models/app_user.dart';
import '../services/patient_store.dart';
import 'qr_screen.dart';

const List<String> kBloodTypes = [
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
];

/// Perfil médico del paciente (mockup 7). Muestra los datos guardados y
/// permite editarlos (RF-04, RF-05). Si todavía no hay perfil, abre
/// directamente el formulario.
class MedicalProfileScreen extends StatelessWidget {
  final PatientStore store;
  final AppUser user;

  const MedicalProfileScreen({
    super.key,
    required this.store,
    required this.user,
  });

  void _edit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditMedicalProfileScreen(store: store)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final profile = store.profile;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Perfil médico'),
            actions: [
              if (profile != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () => _edit(context),
                ),
            ],
          ),
          body: profile == null
              ? _empty(context)
              : _details(context, profile),
        );
      },
    );
  }

  Widget _empty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_information_outlined,
              size: 64, color: Colors.grey[500]),
          const SizedBox(height: 16),
          const Text(
            'Todavía no has completado tu perfil médico',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Con tu tipo de sangre y un contacto de emergencia se genera '
            'tu código QR.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _edit(context),
            child: const Text('Completar perfil'),
          ),
        ],
      ),
    );
  }

  Widget _details(BuildContext context, MedicalProfile profile) {
    final meds = store.medications;
    final conditions = profile.conditionsList;
    final allergies = profile.allergies.trim();
    final summary = <String>[
      if (profile.age != null) 'Edad: ${profile.age} años',
      'Tipo de sangre: ${profile.bloodType}',
    ].join(' · ');
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
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
                  displayName(profile, user),
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
                    style: TextStyle(color: Colors.grey[700])),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  allergies.isEmpty
                      ? 'Alergias: ninguna registrada'
                      : 'Alergias: $allergies',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Condiciones médicas'),
              if (conditions.isEmpty)
                _itemCard(
                  icon: Icons.check_circle_outline,
                  color: Colors.grey,
                  title: 'Ninguna registrada',
                )
              else
                for (final c in conditions)
                  _itemCard(
                    icon: Icons.monitor_heart_outlined,
                    color: Colors.teal,
                    title: c,
                  ),
              const SizedBox(height: 20),
              _sectionTitle('Medicamentos actuales'),
              if (meds.isEmpty)
                _itemCard(
                  icon: Icons.medication_outlined,
                  color: Colors.grey,
                  title: 'Sin medicamentos registrados',
                )
              else
                for (final m in meds)
                  _itemCard(
                    icon: Icons.medication,
                    color: primary,
                    title: '${m.name} ${m.dose}',
                    subtitle: everyHoursText(m.dosesPerDay),
                  ),
              const SizedBox(height: 20),
              _sectionTitle('Contacto de emergencia'),
              _itemCard(
                icon: Icons.phone_in_talk_outlined,
                color: Colors.orange,
                title: profile.emergencyContact.fullName,
                subtitle: profile.emergencyContact.phone,
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Ver código QR'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QrScreen(store: store, user: user),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      );

  /// Tarjeta con ícono a la izquierda, como en el mockup 7.
  Widget _itemCard({
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

/// Nombre a mostrar: el del perfil si lo escribió; si no, el provisional
/// sacado del correo.
String displayName(MedicalProfile? profile, AppUser user) {
  final n = profile?.fullName.trim() ?? '';
  return n.isNotEmpty ? n : nameFromUser(user);
}

String nameFromUser(AppUser user) {
  if (user.fullName.trim().isNotEmpty) return user.fullName.trim();
  final at = user.email.indexOf('@');
  return at > 0 ? user.email.substring(0, at) : user.email;
}

/// Formulario del perfil médico (RF-04, RF-05).
///
/// No permite guardar si faltan el tipo de sangre o el contacto de
/// emergencia. Cada guardado genera un QR nuevo (RF-06).
class EditMedicalProfileScreen extends StatefulWidget {
  final PatientStore store;

  const EditMedicalProfileScreen({super.key, required this.store});

  @override
  State<EditMedicalProfileScreen> createState() =>
      _EditMedicalProfileScreenState();
}

class _EditMedicalProfileScreenState extends State<EditMedicalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();

  String? _bloodType;
  String? _bloodTypeError;

  bool get _isEditing => widget.store.hasProfile;

  @override
  void initState() {
    super.initState();
    final p = widget.store.profile;
    if (p != null) {
      _bloodType = p.bloodType;
      _nameCtrl.text = p.fullName;
      _ageCtrl.text = p.age?.toString() ?? '';
      _allergiesCtrl.text = p.allergies;
      _conditionsCtrl.text = p.conditions;
      _contactNameCtrl.text = p.emergencyContact.fullName;
      _contactPhoneCtrl.text = p.emergencyContact.phone;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final bloodError = Validators.bloodType(_bloodType);
    final formOk = _formKey.currentState?.validate() ?? false;
    setState(() => _bloodTypeError = bloodError);
    if (bloodError != null || !formOk) return;

    widget.store.saveProfile(MedicalProfile(
      fullName: _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()),
      bloodType: _bloodType!,
      allergies: _allergiesCtrl.text.trim(),
      conditions: _conditionsCtrl.text.trim(),
      emergencyContact: EmergencyContact(
        fullName: _contactNameCtrl.text.trim(),
        phone: _contactPhoneCtrl.text.trim(),
      ),
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? 'Perfil actualizado. Tu código QR se generó de nuevo.'
            : 'Perfil guardado. Ya tienes tu código QR.'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar perfil médico' : 'Completar perfil'),
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
                _label('Nombre completo (opcional)'),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _decoration('Ej. Juan Pérez'),
                  validator: Validators.optionalFullName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _label('Edad (opcional)'),
                TextFormField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                  decoration: _decoration('Ej. 28'),
                  validator: Validators.optionalAge,
                ),
                const SizedBox(height: 4),
                _label('Tipo de sangre (obligatorio)'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in kBloodTypes)
                      ChoiceChip(
                        label: Text(t),
                        selected: _bloodType == t,
                        onSelected: (_) => setState(() {
                          _bloodType = t;
                          _bloodTypeError = null;
                        }),
                      ),
                  ],
                ),
                if (_bloodTypeError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_bloodTypeError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 20),
                _label('Alergias (opcional)'),
                TextFormField(
                  controller: _allergiesCtrl,
                  maxLines: 2,
                  decoration: _decoration('Ej. penicilina, polen'),
                  validator: Validators.freeTextMax(200),
                ),
                const SizedBox(height: 16),
                _label('Condiciones médicas (opcional)'),
                TextFormField(
                  controller: _conditionsCtrl,
                  maxLines: 2,
                  decoration:
                      _decoration('Ej. Diabetes tipo 2, Hipertensión arterial'),
                  validator: Validators.freeTextMax(300),
                ),
                const SizedBox(height: 24),
                Text('Contacto de emergencia (obligatorio)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _label('Nombre completo'),
                TextFormField(
                  controller: _contactNameCtrl,
                  decoration: _decoration('Nombre del contacto'),
                  validator: Validators.fullName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _label('Teléfono'),
                TextFormField(
                  controller: _contactPhoneCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  decoration: _decoration('3001234567'),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(
                        _isEditing ? 'Guardar cambios' : 'Guardar perfil'),
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
