import '../models/app_user.dart';

/// Resultado de un intento de registro.
class RegisterResult {
  final bool success;
  final String? errorMessage;

  const RegisterResult.ok() : success = true, errorMessage = null;
  const RegisterResult.error(this.errorMessage) : success = false;
}

/// Contrato de autenticación. La implementación real con Firebase
/// (firebase_auth + cloud_firestore / sqflite) se conecta aquí sin
/// cambiar la pantalla de registro.
///
/// RF-01: crear cuenta con correo/contraseña y guardar nombre, teléfono,
/// rol y, si es paciente, el perfil médico inicial en la misma
/// operación.
abstract class AuthService {
  Future<RegisterResult> register(RegisterData data);
}

/// Implementación en memoria para desarrollar y probar la UI sin
/// depender todavía de Firebase. Simula la regla "correo ya registrado"
/// de RF-01.
class MockAuthService implements AuthService {
  final Set<String> _registeredEmails = {};

  @override
  Future<RegisterResult> register(RegisterData data) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final emailKey = data.email.trim().toLowerCase();
    if (_registeredEmails.contains(emailKey)) {
      return const RegisterResult.error(
        'Ya existe una cuenta registrada con este correo electrónico',
      );
    }

    _registeredEmails.add(emailKey);
    return const RegisterResult.ok();
  }
}

/// Esqueleto de la implementación real con Firebase.
///
/// Para activarla:
/// 1. Ejecuta `flutterfire configure` en el proyecto (genera
///    firebase_options.dart).
/// 2. Llama a `Firebase.initializeApp(...)` en `main()`.
/// 3. Reemplaza `MockAuthService()` por `FirebaseAuthService()` donde
///    se construye el `Provider<AuthService>`.
///
/// Dejado comentado a propósito para no romper la compilación mientras
/// el proyecto Firebase todavía no está configurado.
///
/// ```dart
/// class FirebaseAuthService implements AuthService {
///   final _auth = FirebaseAuth.instance;
///   final _db = FirebaseFirestore.instance;
///
///   @override
///   Future<RegisterResult> register(RegisterData data) async {
///     try {
///       final credential = await _auth.createUserWithEmailAndPassword(
///         email: data.email.trim(),
///         password: data.password,
///       );
///
///       await _db.collection('users').doc(credential.user!.uid).set({
///         'fullName': data.fullName.trim(),
///         'phone': data.phone.trim(),
///         'role': data.role.name,
///         if (data.medicalProfile != null)
///           'medicalProfile': data.medicalProfile!.toMap(),
///       });
///
///       return const RegisterResult.ok();
///     } on FirebaseAuthException catch (e) {
///       if (e.code == 'email-already-in-use') {
///         return const RegisterResult.error(
///           'Ya existe una cuenta registrada con este correo electrónico',
///         );
///       }
///       return RegisterResult.error(e.message ?? 'No se pudo completar el registro');
///     }
///   }
/// }
/// ```
class FirebaseAuthServicePlaceholder {}
