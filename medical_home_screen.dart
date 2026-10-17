import 'package:flutter/material.dart';
import 'scan_patient_qr_screen.dart';

const blue = Color(0xFF1675D1);
const ink = Color(0xFF20334A);
const muted = Color(0xFF75869A);
const line = Color(0xFFE1EAF2);

class MedicalHomeScreen extends StatefulWidget {
  const MedicalHomeScreen({super.key});
  @override
  State<MedicalHomeScreen> createState() => _MedicalHomeScreenState();
}

class _MedicalHomeScreenState extends State<MedicalHomeScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: tab == 0 ? _home() : Center(
          child: Text(tab == 1 ? 'Pacientes' : 'Mi perfil',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: ink)),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        onTap: (value) => setState(() => tab = value),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: blue,
        unselectedItemColor: muted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_2_outlined), label: 'Pacientes'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _home() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Row(children: [
        const CircleAvatar(radius: 24, backgroundColor: Color(0xFFDCEEFF),
          child: Icon(Icons.medical_services_outlined, color: blue, size: 28)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hola, Dra. Laura', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
          Text('Personal médico', style: TextStyle(color: muted, fontSize: 13)),
        ])),
        IconButton(onPressed: () => _message('No tienes notificaciones nuevas.'),
          icon: const Icon(Icons.notifications_none, color: ink)),
      ]),
      const SizedBox(height: 24),
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(
            builder: (_) => const _ScannerPage())),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [blue, Color(0xFF075DB5)]),
              borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Escanear código QR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text('Accede al perfil médico\ndel paciente.', style: TextStyle(color: Colors.white70, height: 1.4)),
              ])),
              Container(width: 76, height: 76,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 48)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 28),
      const Text('Accesos rápidos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
      const SizedBox(height: 12),
      _QuickTile(icon: Icons.groups_2_outlined, title: 'Pacientes registrados',
        onTap: () => _message('Aquí aparecerá la lista de pacientes registrados.')),
      const SizedBox(height: 10),
      _QuickTile(icon: Icons.qr_code_scanner, title: 'Historial de escaneos',
        onTap: () => _message('Aquí aparecerá el historial de escaneos QR.')),
      const SizedBox(height: 10),
      _QuickTile(icon: Icons.notifications_none, title: 'Notificaciones',
        onTap: () => _message('No tienes notificaciones nuevas.')),
    ],
  );

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(border: Border.all(color: line, width: 1.2),
          borderRadius: BorderRadius.circular(15)),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: const BoxDecoration(color: Color(0xFFEAF5FF), shape: BoxShape.circle),
            child: Icon(icon, color: blue, size: 23)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 13))),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8092A6), size: 24),
        ]),
      ),
    ),
  );
}

class _ScannerPage extends StatelessWidget {
  const _ScannerPage();

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const ScanPatientQrScreen(),
    ),
  );

  /*@override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Escanear código QR'),
      backgroundColor: Colors.white, foregroundColor: ink),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 28),
        const Text('Enfoca el código QR del paciente dentro del recuadro.',
          textAlign: TextAlign.center, style: TextStyle(color: ink, fontSize: 16, height: 1.5)),
        const SizedBox(height: 32),
        Expanded(child: Center(child: AspectRatio(aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: blue, width: 3),
              borderRadius: BorderRadius.circular(28)),
            child: const Center(child: Icon(Icons.qr_code_scanner, color: blue, size: 110)),
          )))),
        const SizedBox(height: 24),
        const Text('Pantalla de demostración. Para activar la cámara, integra un paquete de escaneo QR.',
          textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
        const SizedBox(height: 20),
      ]),
    ),
  );*/
}
