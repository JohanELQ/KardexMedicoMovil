import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/validators.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

/// Pantalla de registro (RF-01), igual al mockup oficial: correo,
/// contraseña (con checklist de reglas en vivo) y rol. El nombre, el
/// teléfono y la información médica (RF-04) se completan después,
/// desde otra pantalla.
class RegisterScreen extends StatefulWidget {
  final AuthService authService;

  const RegisterScreen({super.key, required this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _documentCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  UserRole _role = UserRole.paciente;

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _submitError;

  // Estado del checklist de contraseña, se recalcula en cada cambio.
  bool _hasMinMaxLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_updatePasswordChecklist);
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_updatePasswordChecklist);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _documentCtrl.dispose();
    _licenseCtrl.dispose();
    _specialtyCtrl.dispose();
    super.dispose();
  }

  void _updatePasswordChecklist() {
    final v = _passwordCtrl.text;
    setState(() {
      _hasMinMaxLength = v.length >= 8 && v.length <= 20;
      _hasUpper = RegExp(r'[A-Z]').hasMatch(v);
      _hasLower = RegExp(r'[a-z]').hasMatch(v);
      _hasDigit = RegExp(r'\d').hasMatch(v);
      _hasSpecial =
          RegExp(r'[!@#\$%\^&\*\(\)\-_=\+\[\]{};:,.<>?/]').hasMatch(v);
    });
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _submitting = true);

    final data = RegisterData(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _role,
      professional: _role == UserRole.personalMedico
          ? ProfessionalData(
              document: _documentCtrl.text.trim(),
              license: _licenseCtrl.text.trim(),
              specialty: _specialtyCtrl.text.trim(),
            )
          : null,
    );

    final result = await widget.authService.register(data);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_role == UserRole.personalMedico
              ? 'Cuenta creada. Un administrador verificará tus datos '
                  'antes de que puedas escanear.'
              : 'Cuenta creada correctamente'),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginScreen(authService: widget.authService),
        ),
      );
    } else {
      setState(() => _submitError = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
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
                Text('Crear cuenta',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Completa la información para registrarte',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),

                _label('Correo electrónico'),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('usuario@dominio.com')
                      .copyWith(prefixIcon: const Icon(Icons.mail_outline)),
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                _label('Contraseña'),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration('••••••••').copyWith(
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: Validators.password,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 10),
                _passwordChecklist(),
                const SizedBox(height: 20),

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

                if (_role == UserRole.personalMedico) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_outlined,
                            size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Para proteger a los pacientes, un administrador '
                            'verifica a los médicos antes de darles acceso al '
                            'escaneo.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('Documento de identidad'),
                  TextFormField(
                    controller: _documentCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 12,
                    decoration: _fieldDecoration('Solo números'),
                    validator: Validators.document,
                  ),
                  _label('Registro médico / tarjeta profesional'),
                  TextFormField(
                    controller: _licenseCtrl,
                    maxLength: 20,
                    decoration: _fieldDecoration('Ej. RM-123456'),
                    validator: Validators.professionalLicense,
                  ),
                  _label('Especialidad'),
                  TextFormField(
                    controller: _specialtyCtrl,
                    maxLength: 60,
                    decoration: _fieldDecoration('Ej. Medicina general'),
                    validator: Validators.specialty,
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
                        : const Text('Registrarse'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(
                                    authService: widget.authService),
                              ),
                            ),
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: const [
                          TextSpan(text: '¿Ya tienes una cuenta? '),
                          TextSpan(
                            text: 'Inicia sesión',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _checkItem('8-20 caracteres', _hasMinMaxLength),
        _checkItem('1 mayúscula', _hasUpper),
        _checkItem('1 minúscula', _hasLower),
        _checkItem('1 número', _hasDigit),
        _checkItem('1 carácter especial (ej. !@#\$%)', _hasSpecial),
      ],
    );
  }

  Widget _checkItem(String text, bool satisfied) {
    final color = satisfied ? Colors.green : Colors.grey[600];
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

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
