import 'package:flutter/material.dart';

import 'screens/register_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const KardexApp());
}

class KardexApp extends StatelessWidget {
  const KardexApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MockAuthService permite probar la pantalla de registro sin tener
    // Firebase configurado todavía. Cuando el proyecto Firebase esté
    // listo, reemplaza esto por la implementación real (ver
    // services/auth_service.dart).
    final authService = MockAuthService();

    return MaterialApp(
      title: 'Kardex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: RegisterScreen(authService: authService),
    );
  }
}
