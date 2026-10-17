import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/app_user.dart';
import '../services/patient_store.dart';
import 'medical_profile_screen.dart';

/// Código QR de emergencia en grande (mockup 8, RF-06).
class QrScreen extends StatelessWidget {
  final PatientStore store;
  final AppUser user;

  const QrScreen({super.key, required this.store, required this.user});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B1D3A);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final data = store.qrData;
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            foregroundColor: Colors.white,
            title: const Text('Código QR de emergencia'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: data == null
                    ? _noProfile(context)
                    : _qr(context, data),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _qr(BuildContext context, String data) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(data: data, size: 240),
          const SizedBox(height: 16),
          Text(
            displayName(store.profile, user),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text('ID: ${store.qrShortId}',
              style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 20),
          Text(
            'Escanea este código para acceder al perfil médico en caso de '
            'emergencia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Text(
            'Si actualizas tu perfil, se genera un código nuevo y el '
            'anterior deja de ser válido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir'),
              onPressed: () => _share(context, data),
            ),
          ),
        ],
      ),
    );
  }

  /// Copia al portapapeles un texto con el nombre, el ID y el contenido
  /// del código, para pegarlo en un chat o correo. Compartir como imagen
  /// o con el menú del sistema necesita el paquete `share_plus`, que se
  /// puede agregar más adelante.
  Future<void> _share(BuildContext context, String data) async {
    final text = 'Código QR de emergencia de '
        '${displayName(store.profile, user)}\n'
        'ID: ${store.qrShortId}\n'
        'Código: $data';
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos del código copiados para compartir')),
    );
  }

  Widget _noProfile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.qr_code_2, size: 64, color: Colors.grey[500]),
        const SizedBox(height: 16),
        const Text(
          'Aún no tienes código QR',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Completa tu perfil médico (tipo de sangre y contacto de '
          'emergencia) para generarlo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditMedicalProfileScreen(store: store),
            ),
          ),
          child: const Text('Completar perfil'),
        ),
      ],
    );
  }
}
