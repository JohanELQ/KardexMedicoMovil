import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opciones de tamaño de letra (RNF-09).
enum TextSizeOption {
  system('Del sistema', 'Usa el tamaño de letra del celular', null),
  normal('Normal', 'Tamaño estándar', 1.0),
  large('Grande', 'Letra un 20 % más grande', 1.2),
  extraLarge('Muy grande', 'Letra un 40 % más grande', 1.4);

  final String label;
  final String description;
  final double? factor;
  const TextSizeOption(this.label, this.description, this.factor);
}

/// Ajustes de la app que se guardan en el dispositivo.
/// Por ahora solo el tamaño de letra (RNF-09).
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _key = 'kardex_text_scale_v1';

  TextSizeOption _textSize = TextSizeOption.system;
  TextSizeOption get textSize => _textSize;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_key);
      _textSize = TextSizeOption.values.firstWhere(
        (o) => o.name == name,
        orElse: () => TextSizeOption.system,
      );
      notifyListeners();
    } catch (_) {
      // Sin almacenamiento se usa el tamaño del sistema.
    }
  }

  Future<void> setTextSize(TextSizeOption option) async {
    _textSize = option;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, option.name);
    } catch (_) {}
  }

  /// Escala final: respeta la del sistema (limitada a 2.0 para que no se
  /// rompan las pantallas) o aplica el factor elegido por la persona.
  TextScaler scalerFor(TextScaler system) {
    final f = _textSize.factor;
    if (f == null) {
      return system.clamp(minScaleFactor: 1.0, maxScaleFactor: 2.0);
    }
    return TextScaler.linear(f);
  }
}
