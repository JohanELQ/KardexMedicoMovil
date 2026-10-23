/// Rol del usuario dentro de la app (RF-01, RF-03).
enum UserRole { paciente, personalMedico, administrador }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.paciente:
        return 'Paciente';
      case UserRole.personalMedico:
        return 'Personal médico';
      case UserRole.administrador:
        return 'Administrador';
    }
  }
}

/// Estado de la verificación profesional de un médico.
///
/// Un médico recién registrado queda en [pending] y no puede usar el
/// escaneo hasta que un administrador lo apruebe: según RF-08 el personal
/// médico ve datos de emergencia sin que el paciente autorice, así que
/// hay que comprobar quién es antes de darle ese acceso.
enum VerificationStatus { pending, approved, rejected }

extension VerificationStatusLabel on VerificationStatus {
  String get label {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pendiente';
      case VerificationStatus.approved:
        return 'Aprobada';
      case VerificationStatus.rejected:
        return 'Rechazada';
    }
  }
}

/// Datos profesionales que se piden al registrar un médico.
class ProfessionalData {
  final String document; // documento de identidad
  final String license; // registro médico / tarjeta profesional
  final String specialty;

  const ProfessionalData({
    required this.document,
    required this.license,
    required this.specialty,
  });

  Map<String, String> toMap() => {
        'document': document,
        'license': license,
        'specialty': specialty,
      };

  factory ProfessionalData.fromMap(Map<String, dynamic> m) => ProfessionalData(
        document: (m['document'] ?? '') as String,
        license: (m['license'] ?? '') as String,
        specialty: (m['specialty'] ?? '') as String,
      );
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

/// Perfil médico del paciente (RF-04, RF-05).
///
/// Alergias y condiciones son texto libre y opcionales (máximo 200 y 300
/// caracteres). Si hay varias se separan con comas.
class MedicalProfile {
  /// Nombre y edad son opcionales: el mockup 7 los muestra en el perfil,
  /// pero RF-04 solo exige tipo de sangre y contacto de emergencia.
  final String fullName;
  final int? age;
  final String bloodType;
  final String allergies;
  final String conditions;
  final EmergencyContact emergencyContact;

  const MedicalProfile({
    this.fullName = '',
    this.age,
    required this.bloodType,
    this.allergies = '',
    this.conditions = '',
    required this.emergencyContact,
  });

  /// 'Diabetes tipo 2, Hipertensión' -> ['Diabetes tipo 2', 'Hipertensión'].
  List<String> get conditionsList => conditions
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'age': age,
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

  /// Solo para personal médico: se usa para la verificación.
  final ProfessionalData? professional;

  const RegisterData({
    required this.email,
    required this.password,
    required this.role,
    this.professional,
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

  /// Verificación profesional (solo aplica al personal médico; para los
  /// demás roles siempre es [VerificationStatus.approved]).
  final VerificationStatus verification;
  final ProfessionalData? professional;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.fullName = '',
    this.phone = '',
    this.verification = VerificationStatus.approved,
    this.professional,
  });
}
