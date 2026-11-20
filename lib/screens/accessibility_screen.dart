import 'package:flutter/material.dart';

import '../services/app_settings.dart';

/// Accesibilidad (RNF-09): tamaño de letra ajustable.
class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Accesibilidad')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Tamaño de letra',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Elige el tamaño que te resulte más cómodo. El cambio se '
                'aplica a toda la app.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vista previa',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimaryContainer)),
                      const SizedBox(height: 6),
                      Text(
                        'Paracetamol 500 mg · 8:00 a. m.',
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final option in TextSizeOption.values)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: option == settings.textSize
                          ? scheme.primary
                          : Colors.grey[300]!,
                      width: option == settings.textSize ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    title: Text(option.label),
                    subtitle: Text(option.description),
                    trailing: option == settings.textSize
                        ? Icon(Icons.check_circle, color: scheme.primary)
                        : const Icon(Icons.circle_outlined),
                    onTap: () => settings.setTextSize(option),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
