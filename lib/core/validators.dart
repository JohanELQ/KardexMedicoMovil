/// Validadores centralizados para los formularios de la app (RF-24).
///
/// Cada función recibe el valor crudo del campo y devuelve `null` si es
/// válido, o un mensaje de error legible para mostrar bajo el campo si
/// no lo es. Pensados para usarse directamente en el `validator` de un
/// `TextFormField`.
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  // Al menos: 1 mayúscula, 1 minúscula, 1 dígito, 1 carácter especial.
  static final RegExp _hasUpper = RegExp(r'[A-Z]');
  static final RegExp _hasLower = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _hasSpecial = RegExp(r'[!@#\$%\^&\*\(\)\-_=\+\[\]{};:,.<>?/]');

  static final RegExp _phoneRegex = RegExp(r'^\d{10}$');

  /// Nombre completo: obligatorio, mínimo 3 caracteres (RF-01, RF-04).
  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El nombre completo es obligatorio';
    if (v.length < 3) return 'Debe tener al menos 3 caracteres';
    return null;
  }

  /// Nombre del paciente en el perfil: opcional, pero si se escribe
  /// debe tener entre 3 y 60 caracteres.
  static String? optionalFullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.length < 3) return 'Debe tener al menos 3 caracteres';
    if (v.length > 60) return 'Máximo 60 caracteres';
    return null;
  }

  /// Edad opcional: solo dígitos, entre 0 y 120 (RF-24).
  static String? optionalAge(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(v)) return 'Solo se permiten números';
    final n = int.tryParse(v);
    if (n == null || n > 120) return 'Ingresa una edad entre 0 y 120';
    return null;
  }

  /// Correo electrónico con formato usuario@dominio.com (RF-01, RF-24).
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El correo electrónico es obligatorio';
    if (!_emailRegex.hasMatch(v)) {
      return 'Ingresa un correo con formato válido (usuario@dominio.com)';
    }
    return null;
  }

  /// Contraseña: 8–20 caracteres, mayúscula, minúscula, número y
  /// carácter especial (RF-01, RF-24).
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'La contraseña es obligatoria';
    if (v.length < 8 || v.length > 20) {
      return 'Debe tener entre 8 y 20 caracteres';
    }
    if (!_hasUpper.hasMatch(v)) return 'Debe incluir al menos una mayúscula';
    if (!_hasLower.hasMatch(v)) return 'Debe incluir al menos una minúscula';
    if (!_hasDigit.hasMatch(v)) return 'Debe incluir al menos un número';
    if (!_hasSpecial.hasMatch(v)) {
      return 'Debe incluir al menos un carácter especial (!, @, #, \$, %)';
    }
    return null;
  }

  /// Confirmación de contraseña: debe coincidir exactamente (RF-01).
  static String? Function(String?) confirmPassword(
    String Function() getPassword,
  ) {
    return (String? value) {
      final v = value ?? '';
      if (v.isEmpty) return 'Confirma tu contraseña';
      if (v != getPassword()) return 'Las contraseñas no coinciden';
      return null;
    };
  }

  /// Número de teléfono: exactamente 10 dígitos numéricos (RF-01, RF-04).
  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El número de teléfono es obligatorio';
    if (!_phoneRegex.hasMatch(v)) {
      return 'Debe tener 10 dígitos numéricos';
    }
    return null;
  }

  /// Teléfono opcional de contactos de emergencia adicionales.
  static String? optionalPhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return phone(v);
  }

  /// Campo de texto libre opcional con un máximo de caracteres
  /// (alergias, condiciones preexistentes — RF-01, RF-04).
  static String? Function(String?) freeTextMax(int maxLength) {
    return (String? value) {
      final v = value?.trim() ?? '';
      if (v.length > maxLength) {
        return 'Máximo $maxLength caracteres';
      }
      return null;
    };
  }

  /// Nombre del medicamento: 2 a 60 caracteres, obligatorio (RF-10).
  static String? medicationName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El nombre del medicamento es obligatorio';
    if (v.length < 2 || v.length > 60) {
      return 'Debe tener entre 2 y 60 caracteres';
    }
    return null;
  }

  /// Dosis obligatoria, por ejemplo '50 mg' (RF-10).
  static String? dose(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'La dosis es obligatoria';
    if (v.length > 40) return 'Máximo 40 caracteres';
    return null;
  }

  /// Cantidad de dosis disponibles: entero mayor a 0 (RF-10, RF-24).
  static String? totalDoses(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'La cantidad de dosis es obligatoria';
    if (!RegExp(r'^\d+$').hasMatch(v)) return 'Solo se permiten números';
    final n = int.tryParse(v);
    if (n == null || n <= 0) return 'Debe ser un número mayor a 0';
    if (n > 9999) return 'Máximo 9999';
    return null;
  }

  /// Documento de identidad del médico: solo dígitos, 6 a 12.
  static String? document(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El documento es obligatorio';
    if (!RegExp(r'^\d+$').hasMatch(v)) return 'Solo se permiten números';
    if (v.length < 6 || v.length > 12) return 'Debe tener entre 6 y 12 dígitos';
    return null;
  }

  /// Registro médico o tarjeta profesional: letras y números, 4 a 20.
  static String? professionalLicense(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El registro médico es obligatorio';
    if (!RegExp(r'^[A-Za-z0-9\-]+$').hasMatch(v)) {
      return 'Solo letras, números y guiones';
    }
    if (v.length < 4 || v.length > 20) return 'Debe tener entre 4 y 20 caracteres';
    return null;
  }

  /// Especialidad del médico: obligatoria, 3 a 60 caracteres.
  static String? specialty(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'La especialidad es obligatoria';
    if (v.length < 3 || v.length > 60) return 'Debe tener entre 3 y 60 caracteres';
    return null;
  }

  /// Nombre de una farmacia: obligatorio, 2 a 60 caracteres (RF-16).
  static String? pharmacyName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El nombre de la farmacia es obligatorio';
    if (v.length < 2 || v.length > 60) {
      return 'Debe tener entre 2 y 60 caracteres';
    }
    return null;
  }

  /// Dirección de la farmacia: opcional, máximo 100 caracteres.
  static String? pharmacyAddress(String? value) {
    final v = value?.trim() ?? '';
    if (v.length > 100) return 'Máximo 100 caracteres';
    return null;
  }

  static double? _parseCoordinate(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  /// Latitud: número entre -90 y 90 (RF-16).
  static String? latitude(String? value) {
    if ((value ?? '').trim().isEmpty) return 'La latitud es obligatoria';
    final n = _parseCoordinate(value);
    if (n == null) return 'Escribe un número, por ejemplo 3.4516';
    if (n < -90 || n > 90) return 'Debe estar entre -90 y 90';
    return null;
  }

  /// Longitud: número entre -180 y 180 (RF-16).
  static String? longitude(String? value) {
    if ((value ?? '').trim().isEmpty) return 'La longitud es obligatoria';
    final n = _parseCoordinate(value);
    if (n == null) return 'Escribe un número, por ejemplo -76.5320';
    if (n < -180 || n > 180) return 'Debe estar entre -180 y 180';
    return null;
  }

  /// Radio de detección en metros: entre 50 y 2000 (RF-16).
  static String? radiusMeters(String? value) {
    if ((value ?? '').trim().isEmpty) return 'El radio es obligatorio';
    final n = int.tryParse((value ?? '').trim());
    if (n == null) return 'Solo se permiten números enteros';
    if (n < 50 || n > 2000) return 'Debe estar entre 50 y 2000 metros';
    return null;
  }

  /// Selección obligatoria de tipo de sangre (RF-01, RF-04).
  static String? bloodType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Selecciona el tipo de sangre';
    }
    return null;
  }
}
