import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/notification_store.dart';
import 'login_screen.dart';

/// Panel del administrador: aprueba o rechaza a los médicos que se
/// registraron. Un médico no puede escanear hasta ser aprobado.
class AdminHomeScreen extends StatefulWidget {
  final AppUser user;
  final AuthService authService;

  const AdminHomeScreen({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List<DoctorRequest>? _requests;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.authService.doctorRequests();
    if (!mounted) return;
    setState(() => _requests = list);
  }

  Future<void> _decide(DoctorRequest r, VerificationStatus status) async {
    await widget.authService.setVerification(r.email, status);
    final approved = status == VerificationStatus.approved;
    // El médico se entera la próxima vez que entre.
    await NotificationStore.addFor(
      r.email,
      approved ? 'Cuenta verificada' : 'Verificación rechazada',
      approved
          ? 'Tu cuenta de personal médico fue aprobada. Ya puedes escanear '
              'códigos QR.'
          : 'No pudimos confirmar tus datos profesionales.',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approved
            ? 'Médico aprobado: ${r.email}'
            : 'Solicitud rechazada: ${r.email}'),
      ),
    );
    _load();
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
    final requests = _requests;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Verificación de médicos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: requests == null
          ? const Center(child: CircularProgressIndicator())
          : _list(context, requests),
    );
  }

  Widget _list(BuildContext context, List<DoctorRequest> requests) {
    final pending =
        requests.where((r) => r.status == VerificationStatus.pending).toList();
    final done =
        requests.where((r) => r.status != VerificationStatus.pending).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Sesión: ${widget.user.email}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 16),
        const Text('Pendientes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No hay solicitudes pendientes.',
                style: TextStyle(color: Colors.grey[600])),
          )
        else
          for (final r in pending) _pendingCard(r),
        const SizedBox(height: 20),
        const Text('Resueltas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (done.isEmpty)
          Text('Todavía no hay solicitudes resueltas.',
              style: TextStyle(color: Colors.grey[600]))
        else
          for (final r in done)
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: ListTile(
                title: Text(r.email),
                subtitle: Text(
                    '${r.professional.specialty} · ${r.status.label}'),
                trailing: Icon(
                  r.status == VerificationStatus.approved
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: r.status == VerificationStatus.approved
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
      ],
    );
  }

  Widget _pendingCard(DoctorRequest r) {
    final p = r.professional;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.email,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Documento: ${p.document}'),
            Text('Registro médico: ${p.license}'),
            Text('Especialidad: ${p.specialty}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decide(r, VerificationStatus.rejected),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _decide(r, VerificationStatus.approved),
                    child: const Text('Aprobar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
