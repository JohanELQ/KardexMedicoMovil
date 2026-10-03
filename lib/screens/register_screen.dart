import 'package:flutter/material.dart';

import '../core/validators.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Pantalla de registro (RF-01).
///
/// Captura cuenta (nombre, correo, contraseña + confirmación, teléfono,
/// rol) y, si el rol elegido es Paciente, además la información médica
/// inicial (tipo de sangre, hasta 2 alergias, hasta 2 condiciones y un
/// contacto de emergencia obligatorio), todo en el mismo formulario,
/// como en el mockup.
class RegisterScreen extends StatefulWidget {
  final AuthService authService;

  const RegisterScreen({super.key, required this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Cuenta
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  UserRole _role = UserRole.paciente;

  // Información médica (solo si _role == paciente)
  final _bloodTypeOptions = const [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];
  String? _bloodType;
  final _allergy1Ctrl = TextEditingController();
  final _allergy2Ctrl = TextEditingController();
  final _condition1Ctrl = TextEditingController();
  final _condition2Ctrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _submitError;

  bool get _isPaciente => _role == UserRole.paciente;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    _allergy1Ctrl.dispose();
    _allergy2Ctrl.dispose();
    _condition1Ctrl.dispose();
    _condition2Ctrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);

    final isValid = _formKey.currentState?.validate() ?? false;

    // Validación adicional de tipo de sangre: no es un TextFormField
    // normal, así que se valida aparte (RF-01: obligatorio si es paciente).
    final bloodTypeError =
        _isPaciente ? Validators.bloodType(_bloodType) : null;

    if (!isValid || bloodTypeError != null) {
      if (bloodTypeError != null) {
        setState(() => _submitError = bloodTypeError);
      }
      return;
    }

    setState(() => _submitting = true);

    final medicalProfile = _isPaciente
        ? MedicalProfile(
            bloodType: _bloodType!,
            allergies: [_allergy1Ctrl.text, _allergy2Ctrl.text]
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
            conditions: [_condition1Ctrl.text, _condition2Ctrl.text]
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
            emergencyContact: EmergencyContact(
              fullName: _emergencyNameCtrl.text.trim(),
              phone: _emergencyPhoneCtrl.text.trim(),
            ),
          )
        : null;

    final data = RegisterData(
      fullName: _fullNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim(),
      role: _role,
      medicalProfile: medicalProfile,
    );

    final result = await widget.authService.register(data);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada correctamente')),
      );
      // TODO: navegar a la pantalla principal según el rol (RF-03).
    } else {
      setState(() => _submitError = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página de registro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crear usuario',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Ingresa tus datos para crear tu perfil médico',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 20),

                _label('Nombre completo'),
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: _inputDecoration('Enter your full name'),
                  validator: Validators.fullName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                _label('Correo electrónico'),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      _inputDecoration('your.email@example.com'),
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                _label('Contraseña'),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration('••••••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                _label('Confirmar contraseña'),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  decoration: _inputDecoration('••••••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator:
                      Validators.confirmPassword(() => _passwordCtrl.text),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                _label('Número de teléfono'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('3001234567'),
                  validator: Validators.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                _label('Rol'),
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(
                      value: UserRole.paciente,
                      label: Text('Paciente'),
                    ),
                    ButtonSegment(
                      value: UserRole.personalMedico,
                      label: Text('Personal médico'),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: (selection) {
                    setState(() => _role = selection.first);
                  },
                ),

                if (_isPaciente) ...[
                  const SizedBox(height: 28),
                  Text('Información médica',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),

                  _label('Tipo de sangre'),
                  DropdownButtonFormField<String>(
                    initialValue: _bloodType,
                    decoration: _inputDecoration('Ej. O+'),
                    items: _bloodTypeOptions
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _bloodType = v),
                  ),
                  const SizedBox(height: 16),

                  _label('Alergias 1'),
                  TextFormField(
                    controller: _allergy1Ctrl,
                    decoration: _inputDecoration('Ej. penicilina'),
                    validator: Validators.freeTextMax(200),
                  ),
                  const SizedBox(height: 16),

                  _label('Alergias 2'),
                  TextFormField(
                    controller: _allergy2Ctrl,
                    decoration: _inputDecoration('Ej. penicilina'),
                    validator: Validators.freeTextMax(200),
                  ),
                  const SizedBox(height: 16),

                  _label('Condiciones médicas 1'),
                  TextFormField(
                    controller: _condition1Ctrl,
                    decoration: _inputDecoration('Ej. Ninguna registrada'),
                    validator: Validators.freeTextMax(300),
                  ),
                  const SizedBox(height: 16),

                  _label('Condiciones médicas 2'),
                  TextFormField(
                    controller: _condition2Ctrl,
                    decoration: _inputDecoration('Ej. Ninguna registrada'),
                    validator: Validators.freeTextMax(300),
                  ),
                  const SizedBox(height: 16),

                  _label('Contacto de emergencia'),
                  TextFormField(
                    controller: _emergencyNameCtrl,
                    decoration: _inputDecoration('Nombre completo'),
                    validator: Validators.fullName,
                  ),
                  const SizedBox(height: 16),

                  _label('Teléfono de emergencia'),
                  TextFormField(
                    controller: _emergencyPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('3001234567'),
                    validator: Validators.phone,
                  ),
                ],

                if (_submitError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _submitError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Registrar usuario'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    child: const Text('Volver al inicio'),
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
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
