import '../models/app_user.dart';

/// Resultado de un intento de registro.
class RegisterResult {
  final bool success;
  final String? errorMessage;

  const RegisterResult.ok() : success = true, errorMessage = null;
  const RegisterResult.error(this.errorMessage) : success = false;
}

/// Resultado de un intento de inicio de sesión (RF-02).
class LoginResult {
  final bool success;
  final AppUser? user;
  final String? errorMessage;

  const LoginResult.ok(this.user) : success = true, errorMessage = null;
  const LoginResult.error(this.errorMessage)
      : success = false,
        user = null;
}

/// Contrato de autenticación. La implementación real con Firebase
/// (firebase_auth + cloud_firestore / sqflite) se conecta aquí sin
/// cambiar las pantallas de registro/login.
///
/// RF-01: crear cuenta con correo, contraseña y rol.
/// RF-02: iniciar sesión validando credenciales, con bloqueo temporal
/// tras 5 intentos fallidos consecutivos.
/// RF-19: solicitar recuperación de contraseña. No devuelve si el
/// correo existe o no en el sistema — la pantalla siempre muestra el
/// mismo mensaje de confirmación, sin importar el resultado interno.
abstract class AuthService {
  Future<RegisterResult> register(RegisterData data);
  Future<LoginResult> login(LoginData data);
  Future<void> requestPasswordReset(String email);
}

/// Implementación en memoria para desarrollar y probar la UI sin
/// depender todavía de Firebase.
///
/// Simula:
/// - RF-01: rechazo de correo ya registrado.
/// - RF-02: validación de credenciales, bloqueo de 15 minutos tras 5
///   intentos fallidos consecutivos para la misma cuenta, y mensaje de
///   error genérico que no revela cuál campo fue el incorrecto.
class MockAuthService implements AuthService {
  // email (en minúsculas) -> contraseña, simulando la base de usuarios.
  final Map<String, String> _accounts = {};
  final Map<String, UserRole> _roles = {};

  // email -> número de intentos fallidos consecutivos.
  final Map<String, int> _failedAttempts = {};
  // email -> momento hasta el cual la cuenta queda bloqueada.
  final Map<String, DateTime> _lockedUntil = {};

  static const _maxAttempts = 5;
  static const _lockoutDuration = Duration(minutes: 15);

  @override
  Future<RegisterResult> register(RegisterData data) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final emailKey = data.email.trim().toLowerCase();
    if (_accounts.containsKey(emailKey)) {
      return const RegisterResult.error(
        'Ya existe una cuenta registrada con este correo electrónico',
      );
    }

    _accounts[emailKey] = data.password;
    _roles[emailKey] = data.role;
    return const RegisterResult.ok();
  }

  @override
  Future<LoginResult> login(LoginData data) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final emailKey = data.email.trim().toLowerCase();

    final lockedUntil = _lockedUntil[emailKey];
    if (lockedUntil != null) {
      if (DateTime.now().isBefore(lockedUntil)) {
        final minutesLeft =
            lockedUntil.difference(DateTime.now()).inMinutes + 1;
        return LoginResult.error(
          'Demasiados intentos fallidos. Intenta de nuevo en '
          '$minutesLeft minuto(s).',
        );
      }
      // Ya pasó el tiempo de bloqueo: se reinicia el contador.
      _lockedUntil.remove(emailKey);
      _failedAttempts.remove(emailKey);
    }

    final storedPassword = _accounts[emailKey];
    final isValid = storedPassword != null && storedPassword == data.password;

    if (!isValid) {
      final attempts = (_failedAttempts[emailKey] ?? 0) + 1;
      _failedAttempts[emailKey] = attempts;

      if (attempts >= _maxAttempts) {
        _lockedUntil[emailKey] = DateTime.now().add(_lockoutDuration);
      }

      // RF-02: mensaje genérico, sin indicar cuál campo fue el erróneo.
      return const LoginResult.error('Correo o contraseña incorrectos');
    }

    _failedAttempts.remove(emailKey);
    _lockedUntil.remove(emailKey);

    final role = _roles[emailKey] ?? UserRole.paciente;
    return LoginResult.ok(
      AppUser(uid: emailKey, email: data.email.trim(), role: role),
    );
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // No se hace nada visible distinto si el correo existe o no: eso es
    // justamente lo que pide RF-19. En la implementación real con
    // Firebase, aquí se llamaría sendPasswordResetEmail() dentro de un
    // try/catch que ignore el error "user-not-found" por la misma razón.
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
///         'role': data.role.name,
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
///
///   @override
///   Future<LoginResult> login(LoginData data) async {
///     try {
///       final credential = await _auth.signInWithEmailAndPassword(
///         email: data.email.trim(),
///         password: data.password,
///       );
///       final doc = await _db.collection('users').doc(credential.user!.uid).get();
///       final role = doc.data()?['role'] == 'personalMedico'
///           ? UserRole.personalMedico
///           : UserRole.paciente;
///       return LoginResult.ok(AppUser(
///         uid: credential.user!.uid,
///         email: data.email.trim(),
///         role: role,
///       ));
///     } on FirebaseAuthException catch (_) {
///       // Nota: el bloqueo tras 5 intentos fallidos (RF-02) con Firebase
///       // real se implementa guardando los intentos en Firestore, ya
///       // que Firebase Auth no lo hace de forma nativa.
///       return const LoginResult.error('Correo o contraseña incorrectos');
///     }
///   }
/// }
/// ```
class FirebaseAuthServicePlaceholder {}
