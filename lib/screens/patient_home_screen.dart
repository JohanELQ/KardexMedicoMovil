import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../core/format.dart';
import '../services/notification_store.dart';
import '../services/patient_store.dart';
import 'medication_reminder.dart';
import 'medications_tab.dart';
import 'patient_home_tab.dart';
import 'profile_tab.dart';

/// Contenedor del paciente (mockup 5, RF-03): barra inferior con las
/// pestañas Inicio, Medicamentos y Perfil. Todas comparten un mismo
/// [PatientStore], así que lo que se agrega en una se ve en las demás.
class PatientHomeScreen extends StatefulWidget {
  final AppUser user;
  final AuthService authService;

  const PatientHomeScreen({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  late final PatientStore _store = PatientStore(uid: widget.user.uid);
  late final NotificationStore _notifs =
      NotificationStore(uid: widget.user.uid);
  int _tabIndex = 0;
  Timer? _reminderTimer;
  bool _showingReminder = false;

  @override
  void initState() {
    super.initState();
    // Cada 10 segundos revisa si llegó la hora de alguna toma, así el
    // aviso sale con menos de 1 minuto de desvío (RF-11, RNF-04).
    _reminderTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _checkReminders());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReminders());
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _store.dispose();
    _notifs.dispose();
    super.dispose();
  }

  /// RF-14: avisa una vez al día de cada medicamento cuyos días
  /// restantes llegaron al umbral configurado.
  void _checkLowStock(DateTime now) {
    for (final m in _store.medications) {
      if (m.daysRemaining > _notifs.lowStockThreshold) continue;
      if (!_notifs.shouldNotifyLowStock(m.id, now)) continue;
      final body = m.daysRemaining <= 0
          ? 'Se agotó ${m.name}. Repón el medicamento.'
          : '${m.name}: ${daysRemainingText(m.daysRemaining).toLowerCase()}. '
              'Repón el medicamento pronto.';
      _notifs.add('Medicamento por agotarse', body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Medicamento por agotarse: ${m.name}')),
        );
      }
    }
  }

  Future<void> _checkReminders() async {
    if (!mounted) return;
    _checkLowStock(DateTime.now());
    if (_showingReminder) return;
    final dose = _store.nextDueDose(DateTime.now());
    if (dose == null) return;

    _showingReminder = true;
    _store.markAlerted(dose);
    _notifs.add(
      'Recordatorio de medicamento',
      'Es hora de tomar ${dose.medication.name} ${dose.medication.dose}.',
    );
    await showMedicationReminder(
      context: context,
      store: _store,
      dose: dose,
    );
    _showingReminder = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            PatientHomeTab(
              user: widget.user,
              store: _store,
              notifications: _notifs,
              onSeeMedications: () => setState(() => _tabIndex = 1),
            ),
            MedicationsTab(store: _store),
            ProfileTab(
              user: widget.user,
              store: _store,
              notifications: _notifs,
              authService: widget.authService,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.medication_outlined),
              selectedIcon: Icon(Icons.medication),
              label: 'Medicamentos'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }
}
