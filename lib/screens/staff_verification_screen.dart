import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

/// Pantalla que ve un médico mientras su cuenta no está aprobada.
///
/// Mientras esté pendiente o rechazada no puede escanear ni ver datos de
/// pacientes: según RF-08 ese acceso no pide permiso al paciente, así que
/// antes hay que comprobar que quien lo usa es de verdad personal médico.
class StaffVerificationScreen extends StatefulWidget {
  final AppUser user;
  final AuthService authService;
  final VerificationStatus status;
  final ValueChanged<VerificationStatus> onStatusChanged;

  const StaffVerificationScreen({
    super.key,
    required this.user,
    required this.authService,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  State<StaffVerificationScreen> createState() =>
      _StaffVerificationScreenState();
}

class _StaffVerificationScreenState extends State<StaffVerificationScreen> {
  bool _checking = false;

  Future<void> _recheck() async {
    setState(() => _checking = true);
    final status = await widget.authService.verificationOf(widget.user.email);
    if (!mounted) return;
    setState(() => _checking = false);
    if (status == widget.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == VerificationStatus.pending
              ? 'Tu cuenta sigue pendiente de verificación'
              : 'El estado de tu cuenta no ha cambiado'),
        ),
      );
    } else {
      widget.onStatusChanged(status);
    }
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(authService: widget.authService),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rejected = widget.status == VerificationStatus.rejected;
    final prof = widget.user.professional;
    final color = rejected ? Colors.red : Colors.orange;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(
                  rejected ? Icons.block : Icons.hourglass_top,
                  size: 40,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              rejected
                  ? 'No pudimos verificar tu cuenta'
                  : 'Tu cuenta está en verificación',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              rejected
                  ? 'Un administrador revisó tus datos y no pudo confirmar '
                      'que seas personal médico. Si crees que es un error, '
                      'regístrate de nuevo con los datos correctos.'
                  : 'Un administrador revisará tus datos profesionales. '
                      'Cuando tu cuenta sea aprobada podrás escanear los '
                      'códigos QR de los pacientes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (prof != null) ...[
              const SizedBox(height: 24),
              const Text('Datos enviados',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Documento: ${prof.document}'),
                      const SizedBox(height: 4),
                      Text('Registro médico: ${prof.license}'),
                      const SizedBox(height: 4),
                      Text('Especialidad: ${prof.specialty}'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!rejected)
              FilledButton(
                onPressed: _checking ? null : _recheck,
                child: _checking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Revisar estado'),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
