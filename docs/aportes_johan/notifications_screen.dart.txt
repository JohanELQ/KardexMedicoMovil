import 'package:flutter/material.dart';

/// Kardex - Pantalla 12: Notificaciones.
/// Interfaz basada en "Kardex_Mockups_Actualizados", página 7.
/// Esta versión usa datos de ejemplo; conecta NotificationItem con tu backend
/// o base de datos para recibir eventos reales.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color primaryBlue = Color(0xFF0878E5);
  static const Color darkText = Color(0xFF20344A);
  static const Color secondaryText = Color(0xFF7B8DA1);
  static const Color borderColor = Color(0xFFE5EDF5);

  int selectedFilter = 0; // 0 = Todas, 1 = Recordatorios
  int selectedNavigation = 0;

  final List<KardexNotification> _notifications = [
    KardexNotification(
      id: 'dose-1',
      title: 'Recordatorio de medicamento',
      message: 'Lisinopril 10 mg · 08:00 AM',
      time: 'Hoy · 07:50 AM',
      type: NotificationType.reminder,
      read: false,
    ),
    KardexNotification(
      id: 'stock-1',
      title: 'Stock bajo',
      message: 'Lisinopril 10 mg\nQuedan 5 tabletas',
      time: 'Hoy · 10:30 AM',
      type: NotificationType.stock,
      read: false,
    ),
    KardexNotification(
      id: 'geo-1',
      title: 'Geofencing',
      message: 'Estás cerca de una farmacia.',
      time: 'Hoy · 08:20 AM',
      type: NotificationType.geofence,
      read: false,
    ),
    KardexNotification(
      id: 'login-1',
      title: 'Nueva sesión de inicio',
      message: 'Se ha iniciado sesión en tu cuenta\ndesde otro dispositivo.',
      time: 'Ayer · 11:15 AM',
      type: NotificationType.security,
      read: true,
    ),
  ];

  List<KardexNotification> get _visibleNotifications {
    if (selectedFilter == 1) {
      return _notifications
          .where((item) => item.type == NotificationType.reminder)
          .toList();
    }
    return _notifications;
  }

  void _openNotification(KardexNotification item) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == item.id);
      if (index != -1) _notifications[index] = item.copyWith(read: true);
    });

    String details;
    switch (item.type) {
      case NotificationType.reminder:
        details = 'Revisa el horario indicado y registra la toma cuando corresponda.';
        break;
      case NotificationType.stock:
        details = 'Tu registro indica que quedan 5 tabletas. Comprueba el inventario y actualízalo cuando repongas el medicamento.';
        break;
      case NotificationType.geofence:
        details = 'Kardex detectó proximidad a una farmacia registrada mientras tienes una necesidad de medicamento pendiente. La disponibilidad del producto debe confirmarse con la farmacia.';
        break;
      case NotificationType.security:
        details = 'Si no reconoces este acceso, cambia tu contraseña y revisa la seguridad de tu cuenta.';
        break;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
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
              Row(children: [
                _NotificationIcon(type: item.type, size: 46),
                const SizedBox(width: 12),
                Expanded(child: Text(item.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText))),
              ]),
              const SizedBox(height: 16),
              Text(item.message, style: const TextStyle(color: darkText, height: 1.45)),
              const SizedBox(height: 8),
              Text(item.time, style: const TextStyle(color: secondaryText, fontSize: 12)),
              const SizedBox(height: 14),
              Text(details, style: const TextStyle(color: secondaryText, height: 1.45)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNavigationMessage(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sección "$label": conecta aquí la pantalla correspondiente.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Text(
                'Notificaciones',
                style: TextStyle(
                  color: darkText,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(child: _FilterButton(
                    label: 'Todas',
                    selected: selectedFilter == 0,
                    onTap: () => setState(() => selectedFilter = 0),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _FilterButton(
                    label: 'Recordatorios',
                    selected: selectedFilter == 1,
                    onTap: () => setState(() => selectedFilter = 1),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('No hay notificaciones para mostrar.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: borderColor),
                      itemBuilder: (context, index) {
                        final item = visible[index];
                        return _NotificationTile(
                          item: item,
                          onTap: () => _openNotification(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedNavigation,
        onTap: (index) {
          setState(() => selectedNavigation = index);
          if (index != 0) {
            const labels = ['Inicio', 'Medicamentos', 'Historial', 'Perfil'];
            _showNavigationMessage(labels[index]);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: secondaryText,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.medication_outlined), label: 'Medicamentos'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}

enum NotificationType { reminder, stock, geofence, security }

class KardexNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool read;

  const KardexNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.read,
  });

  KardexNotification copyWith({bool? read}) => KardexNotification(
    id: id,
    title: title,
    message: message,
    time: time,
    type: type,
    read: read ?? this.read,
  );
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: selected ? const Color(0xFF0878E5) : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xFF60758B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final KardexNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: item.read ? Colors.transparent : const Color(0xFFFDFEFF),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationIcon(type: item.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: TextStyle(
                    color: const Color(0xFF263B51),
                    fontSize: 13,
                    fontWeight: item.read ? FontWeight.w600 : FontWeight.w800,
                  )),
                  const SizedBox(height: 4),
                  Text(item.message, style: const TextStyle(
                    color: Color(0xFF75899E), fontSize: 12, height: 1.35,
                  )),
                  const SizedBox(height: 5),
                  Text(item.time, style: const TextStyle(
                    color: Color(0xFF8294A7), fontSize: 11,
                  )),
                ],
              ),
            ),
            if (!item.read)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 5, left: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF0878E5),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.type, this.size = 42});
  final NotificationType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color foreground;
    late final Color background;

    switch (type) {
      case NotificationType.reminder:
        icon = Icons.notifications_rounded;
        foreground = const Color(0xFF239B68);
        background = const Color(0xFFE0F6E9);
        break;
      case NotificationType.stock:
        icon = Icons.inventory_2_rounded;
        foreground = const Color(0xFFF06435);
        background = const Color(0xFFFFE9DF);
        break;
      case NotificationType.geofence:
        icon = Icons.location_on_rounded;
        foreground = const Color(0xFF168CE5);
        background = const Color(0xFFE0F2FF);
        break;
      case NotificationType.security:
        icon = Icons.location_on_rounded;
        foreground = const Color(0xFF086FE8);
        background = const Color(0xFFE5F0FF);
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: size * 0.53),
    );
  }
}
