import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/app_settings.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
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

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) => MaterialApp(
      title: 'Kardex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      // RNF-09: tamaño de letra ajustable en toda la app.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
              textScaler: AppSettings.instance.scalerFor(mq.textScaler)),
          child: child!,
        );
      },
      home: SplashScreen(authService: authService),
    ));
  }
}
