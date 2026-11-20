import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/validators.dart';
import '../services/password_recovery_service.dart';

/// Pantalla RF-19. Requiere Firebase inicializado y Authentication habilitado.
class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({
    super.key,
    required this.recoveryService,
  });

  final PasswordRecoveryService recoveryService;

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sending = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
      _sent = false;
    });

    try {
      await widget.recoveryService
          .sendRecoveryEmail(_emailController.text);
      if (!mounted) return;
      setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Mensaje neutral: no revelar si existe una cuenta con ese correo.
      setState(() {
        _sent = true;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error =
          'No fue posible enviar la solicitud. Comprueba tu conexión e inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),
                const Icon(Icons.lock_reset, size: 72, color: Color(0xFF1675D1)),
                const SizedBox(height: 22),
                Text(
                  '¿Olvidaste tu contraseña?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ingresa el correo asociado a tu cuenta. Si corresponde, recibirás un enlace para crear una nueva contraseña.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'usuario@dominio.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validators.email,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                if (_sent) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Si existe una cuenta asociada a ese correo, recibirás instrucciones para restablecer tu contraseña. Revisa también la carpeta de spam.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF16834A)),
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar enlace de recuperación'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
