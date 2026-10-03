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
class RegisterData {
  final String fullName;
  final String email;
  final String password;
  final String phone;
  final UserRole role;
  final MedicalProfile? medicalProfile; // solo cuando role == paciente

  const RegisterData({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.role,
    this.medicalProfile,
  });
}

/// Usuario ya autenticado dentro de la app.
class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
  });
}
