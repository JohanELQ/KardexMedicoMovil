import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Una notificación dentro de la app (la campana).
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  AppNotification markRead() => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        read: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String,
        title: m['title'] as String,
        body: m['body'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        read: (m['read'] ?? false) as bool,
      );
}

/// Notificaciones de un usuario, guardadas en el dispositivo.
///
/// Son avisos dentro de la app (centro de notificaciones con campana).
/// Las notificaciones del sistema con la app cerrada son otra parte
/// (flutter_local_notifications en Android).
class NotificationStore extends ChangeNotifier {
  NotificationStore({required this.uid}) {
    _load();
  }

  final String uid;
  static const _prefix = 'kardex_notifs_v1_';
  static const _maxItems = 60;

  /// RF-14: días restantes en que se avisa de un medicamento por
  /// agotarse. Por defecto 3, configurable de 1 a 10.
  static const defaultThreshold = 3;

  final List<AppNotification> _items = []; // más reciente primero
  final Map<String, String> _lowStockDay = {}; // medicamento -> 'aaaa-mm-dd'
  int _threshold = defaultThreshold;
  bool _disposed = false;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unread => _items.where((n) => !n.read).length;
  int get lowStockThreshold => _threshold;

  String get _key => '$_prefix$uid';

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Guardado y carga
  // ---------------------------------------------------------------

  static Map<String, dynamic> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static List<AppNotification> _itemsFrom(Map<String, dynamic> data) {
    final list = (data['items'] ?? []) as List;
    return list
        .map((e) =>
            AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _decode(prefs.getString(_key));
      _items
        ..clear()
        ..addAll(_itemsFrom(data));
      _threshold = (data['threshold'] ?? defaultThreshold) as int;
      _lowStockDay
        ..clear()
        ..addAll(Map<String, String>.from(
            (data['lowStockDay'] ?? <String, String>{}) as Map));
      if (!_disposed) notifyListeners();
    } catch (_) {
      _items.clear();
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'items': _items.map((n) => n.toJson()).toList(),
          'threshold': _threshold,
          'lowStockDay': _lowStockDay,
        }),
      );
    } catch (_) {
      // Un fallo al guardar no debe romper la pantalla.
    }
  }

  // ---------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void add(String title, String body) {
    _items.insert(
      0,
      AppNotification(
        id: _newId(),
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
    if (_items.length > _maxItems) {
      _items.removeRange(_maxItems, _items.length);
    }
    _save();
    notifyListeners();
  }

  /// Deja una notificación a OTRO usuario (por ejemplo, avisar a un
  /// paciente que un médico consultó su perfil, o a un médico que su
  /// cuenta fue aprobada). Se verá la próxima vez que esa persona entre.
  static Future<void> addFor(String uid, String title, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix$uid';
      final data = _decode(prefs.getString(key));
      final items = _itemsFrom(data);
      items.insert(
        0,
        AppNotification(
          id: _newId(),
          title: title,
          body: body,
          createdAt: DateTime.now(),
        ),
      );
      if (items.length > _maxItems) {
        items.removeRange(_maxItems, items.length);
      }
      data['items'] = items.map((n) => n.toJson()).toList();
      await prefs.setString(key, jsonEncode(data));
    } catch (_) {
      // Si no se pudo guardar, el aviso simplemente no se crea.
    }
  }

  void markAllRead() {
    if (unread == 0) return;
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].markRead();
    }
    _save();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _save();
    notifyListeners();
  }

  void setThreshold(int days) {
    _threshold = days.clamp(1, 10).toInt();
    // Al cambiar el umbral se vuelve a evaluar desde cero.
    _lowStockDay.clear();
    _save();
    notifyListeners();
  }

  /// RF-14: devuelve true si hay que avisar hoy de este medicamento, y
  /// lo anota para no avisar más de una vez por día.
  bool shouldNotifyLowStock(String medicationId, DateTime now) {
    final today = '${now.year}-${now.month}-${now.day}';
    if (_lowStockDay[medicationId] == today) return false;
    _lowStockDay[medicationId] = today;
    _save();
    return true;
  }
}
