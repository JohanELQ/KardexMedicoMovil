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

  /// Selección obligatoria de tipo de sangre (RF-01, RF-04).
  static String? bloodType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Selecciona el tipo de sangre';
    }
    return null;
  }
}
