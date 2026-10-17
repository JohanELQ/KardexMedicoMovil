import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const Color kardexBlue = Color(0xFF16A9FF);
const Color kardexDark = Color(0xFF17232D);

class ScanPatientQrScreen extends StatefulWidget {
  const ScanPatientQrScreen({super.key});

  @override
  State<ScanPatientQrScreen> createState() => _ScanPatientQrScreenState();
}

class _ScanPatientQrScreenState extends State<ScanPatientQrScreen> {
  late final MobileScannerController controller;
  bool torchOn = false;
  bool alreadyScanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> toggleTorch() async {
    try {
      await controller.toggleTorch();
      if (mounted) setState(() => torchOn = !torchOn);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo activar la linterna.')),
      );
    }
  }

  void onDetect(BarcodeCapture capture) {
    if (alreadyScanned) return;
    String? value;
    for (final barcode in capture.barcodes) {
      final candidate = barcode.rawValue;
      if (candidate != null && candidate.trim().isNotEmpty) {
        value = candidate;
        break;
      }
    }
    if (value == null) return;

    setState(() => alreadyScanned = true);
    controller.stop();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ResultSheet(
        value: value!,
        onClose: () {
          Navigator.pop(sheetContext);
          resumeScanner();
        },
        onConsult: () {
          Navigator.pop(sheetContext);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ScannedPatientPlaceholder(value: value!),
            ),
          ).then((_) => resumeScanner());
        },
      ),
    );
  }

  Future<void> resumeScanner() async {
    if (!mounted) return;
    setState(() => alreadyScanned = false);
    try {
      await controller.start();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo reanudar la cámara.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111820),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
            errorBuilder: (context, error) => const ColoredBox(
              color: Color(0xFF1B2731),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No se pudo abrir la cámara. Verifica el permiso de cámara y vuelve a intentarlo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const _CameraShade(),
          SafeArea(
            child: Column(
              children: [
                Container(
                  height: 54,
                  color: const Color(0xCC101820),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'Escanear código QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                const _ScannerFrame(),
                const Spacer(flex: 1),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'Enfoca el código QR del paciente\npara ver su perfil médico.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Material(
                  color: Colors.white.withOpacity(0.08),
                  shape: const CircleBorder(
                    side: BorderSide(color: Colors.white, width: 1.4),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: toggleTorch,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        torchOn ? Icons.flashlight_on : Icons.flashlight_on_outlined,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: const SafeArea(
                    top: false,
                    child: Text(
                      'Escanear QR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF183A5A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraShade extends StatelessWidget {
  const _CameraShade();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.55),
            Colors.black.withOpacity(0.12),
            Colors.black.withOpacity(0.30),
            Colors.black.withOpacity(0.58),
          ],
          stops: const [0, 0.32, 0.65, 1],
        ),
      ),
    ),
  );
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.qr_code_2_rounded, color: Color(0xFF07121C), size: 150),
            ),
          ),
          const _Corner(top: true, left: true),
          const _Corner(top: true, left: false),
          const _Corner(top: false, left: true),
          const _Corner(top: false, left: false),
          const Positioned(left: 0, right: 0, child: _ScanLine()),
        ],
      ),
    ),
  );
}

class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});
  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) => Positioned(
    top: top ? 0 : null,
    bottom: top ? null : 0,
    left: left ? 0 : null,
    right: left ? null : 0,
    child: SizedBox(
      width: 38,
      height: 38,
      child: CustomPaint(painter: _CornerPainter(top: top, left: left)),
    ),
  );
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.top, required this.left});
  final bool top;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBDEBFF)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? 1.0 : -1.0;
    final dy = top ? 1.0 : -1.0;
    final path = Path()
      ..moveTo(x, y + dy * 13)
      ..lineTo(x, y)
      ..lineTo(x + dx * 13, y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.top != top || oldDelegate.left != left;
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late final AnimationController animation;
  late final Animation<double> position;

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    position = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: position,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, (position.value - 0.5) * 178),
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: kardexBlue,
          boxShadow: [
            BoxShadow(color: kardexBlue.withOpacity(0.95), blurRadius: 12, spreadRadius: 2),
          ],
        ),
      ),
    ),
  );
}

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({required this.value, required this.onClose, required this.onConsult});
  final String value;
  final VoidCallback onClose;
  final VoidCallback onConsult;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Código QR detectado',
            style: TextStyle(color: kardexDark, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Contenido leído:', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          SelectableText(value, style: const TextStyle(color: kardexDark, fontSize: 14)),
          const SizedBox(height: 12),
          const Text(
            'Antes de mostrar datos clínicos, valida este identificador con tu servidor y verifica los permisos del profesional.',
            style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
            child: ElevatedButton(onPressed: onConsult, child: const Text('Consultar paciente'))),
          Center(child: TextButton(onPressed: onClose, child: const Text('Escanear otro código'))),
        ],
      ),
    ),
  );
}

/// Pantalla provisional. Sustitúyela por la ficha real del paciente de Kardex.
class ScannedPatientPlaceholder extends StatelessWidget {
  const ScannedPatientPlaceholder({super.key, required this.value});
  final String value;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil del paciente')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.assignment_ind_outlined, size: 58, color: Color(0xFF1675D1)),
        const SizedBox(height: 16),
        const Text('Paciente identificado',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'El código se leyó correctamente. Conecta esta pantalla con el servicio seguro de Kardex para cargar los datos médicos autorizados.'),
        const SizedBox(height: 16),
        const Text('Valor leído:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        SelectableText(value),
      ]),
    ),
  );
}
