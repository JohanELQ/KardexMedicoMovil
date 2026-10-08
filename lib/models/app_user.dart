/// Rol del usuario dentro de la app (RF-01, RF-03).
enum UserRole { paciente, personalMedico }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.paciente:
        return 'Paciente';
      case UserRole.personalMedico:
        return 'Personal médico';
    }
  }
}

/// Contacto de emergencia (RF-04, RF-23).
class EmergencyContact {
  final String fullName;
  final String phone;
  final bool visible;

  const EmergencyContact({
    required this.fullName,
    required this.phone,
    this.visible = true,
  });

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'phone': phone,
        'visible': visible ? 1 : 0,
      };
}

/// Información médica inicial capturada durante el registro cuando el
/// rol es Paciente (RF-01, ampliable luego en RF-04).
class MedicalProfile {
  final String bloodType;
  final List<String> allergies; // hasta 2 en el registro inicial
  final List<String> conditions; // hasta 2 en el registro inicial
  final EmergencyContact emergencyContact;

  const MedicalProfile({
    required this.bloodType,
    this.allergies = const [],
    this.conditions = const [],
    required this.emergencyContact,
  });

  Map<String, dynamic> toMap() => {
        'bloodType': bloodType,
        'allergies': allergies,
        'conditions': conditions,
        'emergencyContact': emergencyContact.toMap(),
      };
}

/// Datos que recoge el formulario de registro (RF-01).
///
/// Según el mockup oficial, el registro solo pide cuenta (correo,
/// contraseña) y rol. El nombre completo, el teléfono y la información
/// médica (RF-04) se completan en otra pantalla, después de iniciar
/// sesión — no aquí.
class RegisterData {
  final String email;
  final String password;
  final UserRole role;

  const RegisterData({
    required this.email,
    required this.password,
    required this.role,
  });
}

/// Datos que recoge el formulario de inicio de sesión (RF-02).
class LoginData {
  final String email;
  final String password;

  const LoginData({required this.email, required this.password});
}

/// Usuario ya autenticado dentro de la app.
///
/// `fullName` y `phone` quedan vacíos hasta que el usuario complete su
/// información personal más adelante (no se piden en el registro).
class AppUser {
  final String uid;
  final String email;
  final UserRole role;
  final String fullName;
  final String phone;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.fullName = '',
    this.phone = '',
  });
}
