import 'package:flutter/material.dart';
import 'notifications_screen.dart';

const blue = Color(0xFF1675D1);
const ink = Color(0xFF20334A);
const muted = Color(0xFF75869A);
const line = Color(0xFFE1EAF2);

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});
  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: tab == 0 ? _home() : Center(
          child: Text(tab == 1 ? 'Medicamentos' : 'Mi perfil',
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
          BottomNavigationBarItem(icon: Icon(Icons.medication_outlined), label: 'Medicamentos'),
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
          child: Icon(Icons.person, color: blue, size: 30)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hola, Juan', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
          Text('Paciente', style: TextStyle(color: muted, fontSize: 13)),
        ])),
        IconButton(onPressed: () => _message('No tienes notificaciones nuevas.'),
          icon: const Icon(Icons.notifications_none, color: ink)),
      ]),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [blue, Color(0xFF075DB5)]),
          borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tu código QR de emergencia', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          const Text('Muestra este código en caso\nde emergencia.', style: TextStyle(color: Colors.white70, height: 1.4)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: blue),
              onPressed: _showQr, child: const Text('Ver código QR'))),
            const SizedBox(width: 16),
            Container(width: 78, height: 78, color: Colors.white,
              child: const Icon(Icons.qr_code_2, size: 68, color: Colors.black)),
          ]),
        ]),
      ),
      const SizedBox(height: 24),
      Row(children: [
        const Expanded(child: Text('Próximas dosis', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink))),
        TextButton(onPressed: () => setState(() => tab = 1), child: const Text('Ver todas')),
      ]),
      const SizedBox(height: 6),
      const _DoseCard(name: 'Paracetamol 500 mg', time: 'Hoy · 08:00 AM',
        icon: Icons.medication, color: Color(0xFFE64C4C), bg: Color(0xFFFFEEEE), done: true),
      const SizedBox(height: 9),
      const _DoseCard(name: 'Lisinopril 10 mg', time: 'Hoy · 02:00 PM',
        icon: Icons.medication_outlined, color: blue, bg: Color(0xFFE6F4FF)),
      const SizedBox(height: 9),
      const _DoseCard(name: 'Metformina 850 mg', time: 'Hoy · 08:00 PM',
        icon: Icons.medication_outlined, color: Color(0xFFEF8A32), bg: Color(0xFFFFF0E1)),
    ],
  );

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  void _showQr() => showDialog<void>(context: context, builder: (_) => AlertDialog(
    title: const Text('Código QR de emergencia'),
    content: const Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.qr_code_2, size: 190),
      Text('Juan Pérez · ID: KDX-001', textAlign: TextAlign.center),
      SizedBox(height: 8),
      Text('QR ilustrativo; no contiene información médica real.', textAlign: TextAlign.center),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
  ));
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({required this.name, required this.time, required this.icon,
    required this.color, required this.bg, this.done = false});
  final String name, time;
  final IconData icon;
  final Color color, bg;
  final bool done;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line),
      borderRadius: BorderRadius.circular(15)),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: ink, fontSize: 13)),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(color: muted, fontSize: 11)),
      ])),
      Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: done ? const Color(0xFF19A765) : const Color(0xFFC8D0D8)),
    ]),
  );
}

ListTile(
  leading: const Icon(
    Icons.notifications_outlined,
    color: Colors.blue,
  ),
  title: const Text('Notificaciones'),
  subtitle: const Text('Recordatorios y alertas de Kardex'),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  },
),
