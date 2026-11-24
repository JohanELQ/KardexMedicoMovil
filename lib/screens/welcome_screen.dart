import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'medical_staff_home_screen.dart';
import 'patient_home_screen.dart';

/// Pantalla de bienvenida tras iniciar sesión (mockup 4).
///
/// RF-03: el sistema debe redirigir según el rol del usuario y no debe
/// permitir, bajo ninguna circunstancia, que acceda a las funciones del
/// rol contrario. Por eso, aunque el mockup muestra las dos tarjetas
/// (Paciente / Personal médico), solo la que coincide con el rol real
/// del usuario autenticado está habilitada; la otra queda deshabilitada
/// para que la navegación real siga siendo automática según el rol.
class WelcomeScreen extends StatelessWidget {
  final AppUser user;
  final AuthService authService;

  const WelcomeScreen({
    super.key,
    required this.user,
    required this.authService,
  });

  bool get _isPaciente => user.role == UserRole.paciente;

  String get _displayName {
    if (user.fullName.trim().isNotEmpty) return user.fullName.trim();
    // Si todavía no se ha completado el nombre, se usa la parte antes
    // de la @ del correo como saludo provisional.
    final at = user.email.indexOf('@');
    return at > 0 ? user.email.substring(0, at) : user.email;
  }

  void _goToRoleHome(BuildContext context) {
    final screen = _isPaciente
        ? PatientHomeScreen(user: user, authService: authService)
        : MedicalStaffHomeScreen(user: user, authService: authService);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _blocked(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu cuenta no tiene acceso a esta sección con tu rol actual'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('¡Bienvenido, $_displayName!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 4),
              Text(
                '¿Qué quieres hacer hoy?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 28),
              _roleCard(
                context,
                icon: Icons.person_outline,
                title: 'Paciente',
                subtitle:
                    'Accede a tu perfil médico, medicamentos y código QR.',
                enabled: _isPaciente,
              ),
              const SizedBox(height: 16),
              _roleCard(
                context,
                icon: Icons.medical_services_outlined,
                title: 'Personal médico',
                subtitle:
                    'Escanea códigos QR y accede a la información de pacientes.',
                enabled: !_isPaciente,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () =>
              enabled ? _goToRoleHome(context) : _blocked(context),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(icon,
                      color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
