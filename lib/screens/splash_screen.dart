import 'dart:async';

import 'package:flutter/material.dart';

import 'login_screen.dart';
import '../services/auth_service.dart';

/// Pantalla de inicio / splash (mockup 1).
///
/// Se muestra brevemente al abrir la app y luego pasa automáticamente
/// al inicio de sesión. Más adelante, cuando exista persistencia de
/// sesión, este es el lugar donde se revisaría si ya hay un usuario
/// autenticado para saltar directo a su pantalla de inicio.
class SplashScreen extends StatefulWidget {
  final AuthService authService;

  const SplashScreen({super.key, required this.authService});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _goToLogin);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(authService: widget.authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0B1D3A);
    const accentColor = Color(0xFF29B6E8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        // Permite saltar el splash tocando la pantalla, por si alguien
        // no quiere esperar los 2 segundos.
        onTap: _goToLogin,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _PulseLinePainter()),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Kardex',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bienvenido a Kardex',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tu historial médico,\nsiempre contigo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dibuja la línea de "pulso" decorativa en la parte baja del splash,
/// igual al mockup.
class _PulseLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF29B6E8).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final baseY = size.height * 0.78;
    path.moveTo(0, baseY);
    path.lineTo(size.width * 0.30, baseY);
    path.lineTo(size.width * 0.38, baseY - 36);
    path.lineTo(size.width * 0.46, baseY + 46);
    path.lineTo(size.width * 0.54, baseY - 14);
    path.lineTo(size.width * 0.62, baseY);
    path.lineTo(size.width, baseY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
