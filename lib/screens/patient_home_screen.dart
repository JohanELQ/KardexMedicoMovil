import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../core/format.dart';
import '../services/notification_store.dart';
import '../services/patient_store.dart';
import '../services/pharmacy_geofencing.dart';
import '../services/pharmacy_store.dart';
import '../services/reminder_planner.dart';
import '../services/system_notifications.dart';
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

class _PatientHomeScreenState extends State<PatientHomeScreen>
    with WidgetsBindingObserver {
  late final PatientStore _store = PatientStore(uid: widget.user.uid);
  late final NotificationStore _notifs =
      NotificationStore(uid: widget.user.uid);
  int _tabIndex = 0;
  Timer? _reminderTimer;
  bool _showingReminder = false;
  final PharmacyGeofencing _geofencing = PharmacyGeofencing();
  DateTime? _lastPharmacyCheck;
  bool _checkingPharmacies = false;
  bool _syncingAlerts = false;
  bool _syncAgain = false;

  @override
  void initState() {
    super.initState();
    // Cada 10 segundos revisa si llegó la hora de alguna toma, así el
    // aviso sale con menos de 1 minuto de desvío (RF-11, RNF-04).
    WidgetsBinding.instance.addObserver(this);
    // RF-11: cada cambio en los medicamentos reprograma los avisos del
    // sistema, que llegan aunque la app esté cerrada.
    _store.addListener(_syncSystemAlerts);
    SystemNotifications.storageChanges.addListener(_onStorageChanged);
    SystemNotifications.instance.requestPermission();
    _geofencing.loadHistory();
    _reminderTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _checkReminders());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReminders());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.removeListener(_syncSystemAlerts);
    SystemNotifications.storageChanges.removeListener(_onStorageChanged);
    _reminderTimer?.cancel();
    _store.dispose();
    _notifs.dispose();
    super.dispose();
  }

  /// Al volver a la app se leen de nuevo los datos: pudo confirmarse una
  /// toma desde la notificación mientras estaba cerrada.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _store.reload();
  }

  void _onStorageChanged() => _store.reload();

  /// RF-11: programa en el sistema los recordatorios de las tomas de los
  /// próximos días. Se repite si llega otro cambio mientras trabaja.
  Future<void> _syncSystemAlerts() async {
    if (_syncingAlerts) {
      _syncAgain = true;
      return;
    }
    _syncingAlerts = true;
    try {
      do {
        _syncAgain = false;
        final now = DateTime.now();
        final alerts = planDoseAlerts(
          uid: widget.user.uid,
          now: now,
          medications: _store.medications,
          todayDoses: _store.dosesForDay(now),
        );
        await SystemNotifications.instance.replaceAll(alerts);
      } while (_syncAgain);
    } catch (_) {
      // Un fallo al programar no debe romper la pantalla.
    } finally {
      _syncingAlerts = false;
    }
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

  /// RF-16 a RF-18: si el paciente activó los avisos y le queda poco de
  /// algún medicamento, revisa (como máximo cada 2 minutos y solo con la
  /// app abierta) si está cerca de una farmacia.
  Future<void> _checkPharmacies(DateTime now) async {
    if (!_notifs.pharmacyAlerts || _checkingPharmacies) return;
    final last = _lastPharmacyCheck;
    if (last != null && now.difference(last) < const Duration(minutes: 2)) {
      return;
    }
    final low = _store.medications
        .where((m) => m.daysRemaining <= _notifs.lowStockThreshold)
        .toList();
    if (low.isEmpty) return;

    _checkingPharmacies = true;
    _lastPharmacyCheck = now;
    try {
      final position = await _geofencing.getCurrentPosition();
      final nearby = _geofencing.findNearbyPharmacies(
        userPosition: position,
        pharmacies: PharmacyStore.instance.pharmacies,
        medications: [
          for (final m in low) NeededMedication(name: m.name, needsRefill: true),
        ],
      );
      for (final p in nearby) {
        _notifs.add(
          'Farmacia cerca',
          pharmacyAlertBody(p, [for (final m in low) m.name]),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Estás cerca de ${p.name}')),
          );
        }
      }
    } catch (_) {
      // Sin permiso o sin ubicación: se intenta de nuevo más tarde.
    } finally {
      _checkingPharmacies = false;
    }
  }

  Future<void> _checkReminders() async {
    if (!mounted) return;
    _checkLowStock(DateTime.now());
    _checkPharmacies(DateTime.now());
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
