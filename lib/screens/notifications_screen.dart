import 'package:flutter/material.dart';

import '../core/format.dart';
import '../services/notification_store.dart';

/// Centro de notificaciones (la campana). Al abrirlo, las notificaciones
/// se marcan como leídas.
///
/// Con [showThreshold] (solo paciente) permite elegir con cuántos días de
/// anticipación se avisa de un medicamento por agotarse (RF-14).
class NotificationsScreen extends StatefulWidget {
  final NotificationStore store;
  final bool showThreshold;

  const NotificationsScreen({
    super.key,
    required this.store,
    this.showThreshold = false,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Las que estaban sin leer al entrar se resaltan aunque se marquen
  // como leídas enseguida.
  late final Set<String> _newOnes;

  @override
  void initState() {
    super.initState();
    _newOnes = {
      for (final n in widget.store.items)
        if (!n.read) n.id,
    };
    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.store.markAllRead());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final items = widget.store.items;
        final now = DateTime.now();
        final primary = Theme.of(context).colorScheme.primary;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificaciones'),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  tooltip: 'Borrar todas',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.store.clear,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.showThreshold) ...[
                const Text('Avisar de medicamentos por agotarse',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Días antes de que se acabe (el aviso sale una vez al día).',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var d = 1; d <= 10; d++)
                      ChoiceChip(
                        label: Text('$d'),
                        selected: widget.store.lowStockThreshold == d,
                        onSelected: (_) => widget.store.setThreshold(d),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey[500]),
                      const SizedBox(height: 16),
                      const Text('No tienes notificaciones',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              else
                for (final n in items)
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: _newOnes.contains(n.id)
                        ? primary.withOpacity(0.06)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _newOnes.contains(n.id)
                            ? primary.withOpacity(0.4)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primary.withOpacity(0.12),
                        child: Icon(Icons.notifications_outlined,
                            color: primary),
                      ),
                      title: Text(n.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${n.body}\n${dayLabel(n.createdAt, now)} · '
                        '${formatTime12(n.createdAt.hour, n.createdAt.minute)}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Campana con el número de notificaciones sin leer.
class NotificationBell extends StatelessWidget {
  final NotificationStore store;
  final VoidCallback onPressed;

  const NotificationBell({
    super.key,
    required this.store,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final count = store.unread;
        return IconButton(
          tooltip: 'Notificaciones',
          onPressed: onPressed,
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.notifications_none),
          ),
        );
      },
    );
  }
}
