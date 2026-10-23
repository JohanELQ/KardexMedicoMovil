import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/validators.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'admin_home_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';

/// Pantalla de inicio de sesión (RF-02), igual al mockup oficial:
/// correo, contraseña, enlace de contraseña olvidada, botón de
/// iniciar sesión y acceso para crear cuenta.
class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  bool _rememberMe = false;
  String? _submitError;

  static const _rememberKey = 'remember_email';

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Si la persona marcó "Recordarme" la vez anterior, deja el correo
  /// ya escrito. Solo se guarda el correo, nunca la contraseña: guardar
  /// contraseñas en texto plano en el dispositivo sería inseguro
  /// (RNF-01).
  Future<void> _loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_rememberKey);
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() {
          _emailCtrl.text = saved;
          _rememberMe = true;
        });
      }
    } catch (_) {
      // Si no se puede leer el almacenamiento, el login sigue
      // funcionando normal, solo sin el correo prellenado.
    }
  }

  Future<void> _saveRememberedEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString(_rememberKey, email);
      } else {
        await prefs.remove(_rememberKey);
      }
    } catch (_) {
      // Mismo criterio: un fallo al guardar no debe bloquear el login.
    }
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _submitting = true);

    final data = LoginData(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    final result = await widget.authService.login(data);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      await _saveRememberedEmail(data.email);
      if (!mounted) return;
      final user = result.user!;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => user.role == UserRole.administrador
              ? AdminHomeScreen(user: user, authService: widget.authService)
              : WelcomeScreen(user: user, authService: widget.authService),
        ),
      );
    } else {
      setState(() => _submitError = result.errorMessage);
    }
  }

  void _showNotAvailable(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inicio de sesión con $provider aún no está disponible')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite,
                        color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kardex',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inicia sesión en tu cuenta',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,
                  child: _label('Correo electrónico'),
                ),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('usuario@dominio.com')
                      .copyWith(prefixIcon: const Icon(Icons.mail_outline)),
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: _label('Contraseña'),
                ),
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
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'La contraseña es obligatoria' : null,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: _submitting
                            ? null
                            : () => setState(() => _rememberMe = !_rememberMe),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: _submitting
                                  ? null
                                  : (v) =>
                                      setState(() => _rememberMe = v ?? false),
                            ),
                            const Flexible(child: Text('Recordarme')),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(
                                      authService: widget.authService),
                                ),
                              ),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ],
                ),

                if (_submitError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _submitError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],

                const SizedBox(height: 16),
                FilledButton(
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
                      : const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(
                                  authService: widget.authService),
                            ),
                          ),
                  child: const Text('Crear cuenta'),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('o', style: TextStyle(color: Colors.grey[600])),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.outlined(
                      onPressed: () => _showNotAvailable('Google'),
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                    ),
                    const SizedBox(width: 16),
                    IconButton.outlined(
                      onPressed: () => _showNotAvailable('Apple'),
                      icon: const Icon(Icons.apple),
                    ),
                  ],
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
