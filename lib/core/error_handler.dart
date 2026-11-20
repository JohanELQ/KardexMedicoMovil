import 'dart:async';

import 'package:flutter/material.dart';

/// Manejador común de errores (RF-25).
///
/// Todos los mensajes de error de la app pasan por aquí, así se ven y se
/// escriben igual en todas las pantallas: dicen qué pasó y, cuando se
/// puede, cómo corregirlo. Se pueden cerrar con la X o se van solos.
class AppErrors {
  AppErrors._();

  /// True si el error se debe a que no hay internet o la conexión falló.
  static bool isConnectionError(Object error) {
    if (error is TimeoutException) return true;
    final type = error.runtimeType.toString();
    final text = error.toString().toLowerCase();
    return type.contains('SocketException') ||
        type.contains('ClientException') ||
        type.contains('HandshakeException') ||
        type.contains('TlsException') ||
        text.contains('network-request-failed') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('connection reset') ||
        text.contains('connection closed') ||
        text.contains('network is unreachable') ||
        text.contains('xmlhttprequest error');
  }

  /// Convierte cualquier error en un mensaje claro para la persona.
  static String messageFor(Object error) {
    if (error is TimeoutException) {
      return 'La operación tardó demasiado. Revisa tu conexión a internet '
          'e inténtalo de nuevo.';
    }
    if (isConnectionError(error)) {
      return 'No hay conexión a internet. Revisa tu Wi-Fi o tus datos '
          'móviles e inténtalo de nuevo.';
    }

    final type = error.runtimeType.toString();
    if (type == 'LocationServiceDisabledException') {
      return 'La ubicación del teléfono está apagada. Actívala en los '
          'ajustes e inténtalo de nuevo.';
    }
    if (type == 'PermissionDeniedException') {
      return 'Kardex no tiene permiso para usar la ubicación. Concédelo en '
          'Perfil → Permisos del dispositivo e inténtalo de nuevo.';
    }
    if (type == 'MissingPluginException' || type == 'PlatformException') {
      return 'Esta función no está disponible en este dispositivo.';
    }
    if (error is FormatException) {
      return 'Hay un dato con formato incorrecto. Revísalo e inténtalo de '
          'nuevo.';
    }

    // Los errores que la propia app lanza ya traen un mensaje claro.
    if (error is Exception) {
      final text = error.toString();
      if (text.startsWith('Exception: ')) {
        return text.substring('Exception: '.length);
      }
    }
    return 'No se pudo completar la acción. Inténtalo de nuevo; si el '
        'problema sigue, cierra y vuelve a abrir la app.';
  }

  /// Muestra un error como aviso rojo, con botón para cerrarlo.
  static void showSnack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.error,
          showCloseIcon: true,
          closeIconColor: scheme.onError,
          duration: const Duration(seconds: 6),
          content: Row(
            children: [
              Icon(Icons.error_outline, color: scheme.onError),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: TextStyle(color: scheme.onError)),
              ),
            ],
          ),
        ),
      );
  }

  /// Convierte [error] en mensaje y lo muestra.
  static void show(BuildContext context, Object error) =>
      showSnack(context, messageFor(error));

  /// Para acciones que devuelven un texto de error o null si salió bien:
  /// muestra el error en rojo o, si no hay, el aviso de éxito.
  static void showResult(
    BuildContext context, {
    String? error,
    required String success,
  }) {
    if (error != null) {
      showSnack(context, error);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(success)));
    }
  }

  /// Para errores que bloquean lo que la persona estaba haciendo.
  static Future<void> showDialogMessage(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.error_outline,
            color: Theme.of(ctx).colorScheme.error, size: 32),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
