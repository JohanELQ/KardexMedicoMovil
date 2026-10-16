import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/patient_store.dart';
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
  int _tabIndex = 0;

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
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
              onSeeMedications: () => setState(() => _tabIndex = 1),
            ),
            MedicationsTab(store: _store),
            ProfileTab(
              user: widget.user,
              store: _store,
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
