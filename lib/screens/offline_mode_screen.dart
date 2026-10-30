import 'package:flutter/material.dart';

/// Modo sin conexión / respaldo local (mockup 18).
///
/// Kardex guarda todo en el dispositivo, así que funciona sin internet.
class OfflineModeScreen extends StatelessWidget {
  const OfflineModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Sin conexión')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 52,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(Icons.cloud_off_outlined, size: 52, color: color),
              ),
              const SizedBox(height: 24),
              const Text(
                'Modo sin conexión',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Tus datos están guardados localmente en el dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              _check('Perfil médico'),
              _check('Medicamentos'),
              _check('Historial de tomas'),
              const SizedBox(height: 20),
              Text(
                'La sincronización en la nube todavía no está disponible: por '
                'ahora tus datos viven solo en este dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _check(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
