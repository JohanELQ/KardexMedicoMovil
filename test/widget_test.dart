import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kardex/core/error_handler.dart';
import 'package:kardex/services/app_settings.dart';

void main() {
  group('Errores de conexión (RF-25)', () {
    test('detecta fallos de red y tiempo de espera', () {
      expect(AppErrors.isConnectionError(TimeoutException('x')), isTrue);
      expect(
          AppErrors.isConnectionError(const SocketException('sin red')), isTrue);
      expect(AppErrors.isConnectionError(StateError('otro')), isFalse);
    });

    test('el mensaje de conexión explica qué hacer', () {
      final msg = AppErrors.messageFor(TimeoutException('x'));
      expect(msg.isNotEmpty, isTrue);
    });
  });

  group('Tamaño de letra (RNF-09)', () {
    test('las opciones fijas tienen factor y la del sistema no', () {
      expect(TextSizeOption.system.factor, isNull);
      expect(TextSizeOption.normal.factor, 1.0);
      expect(TextSizeOption.large.factor, greaterThan(1.0));
      expect(TextSizeOption.extraLarge.factor,
          greaterThan(TextSizeOption.large.factor!));
    });
  });
}
