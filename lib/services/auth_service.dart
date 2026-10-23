import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Verificación de médicos (la usa el administrador).
  Future<List<DoctorRequest>> doctorRequests();
  Future<void> setVerification(String email, VerificationStatus status);
  Future<VerificationStatus> verificationOf(String email);
}

/// Solicitud de verificación de un médico.
class DoctorRequest {
  final String email;
  final ProfessionalData professional;
  final VerificationStatus status;

  const DoctorRequest({
    required this.email,
    required this.professional,
    required this.status,
  });
}

/// Implementación local para desarrollar y probar la UI sin depender
/// todavía de Firebase.
///
/// Las cuentas se guardan en el dispositivo con `shared_preferences`,
/// así que siguen existiendo al cerrar y volver a abrir la app. La
/// contraseña nunca se guarda en texto: solo un hash SHA-256 con sal
/// (RNF-01). Esto es un paso intermedio: cuando se conecte Firebase,
/// las cuentas vivirán en el servidor.
///
/// Simula:
/// - RF-01: rechazo de correo ya registrado.
/// - RF-02: validación de credenciales, bloqueo de 15 minutos tras 5
///   intentos fallidos consecutivos para la misma cuenta, y mensaje de
///   error genérico que no revela cuál campo fue el incorrecto.
class MockAuthService implements AuthService {
  static const _storageKey = 'kardex_accounts_v1';

  // email (en minúsculas) -> { salt, hash, role }
  final Map<String, Map<String, String>> _accounts = {};
  Future<void>? _loading;

  // email -> número de intentos fallidos consecutivos.
  final Map<String, int> _failedAttempts = {};
  // email -> momento hasta el cual la cuenta queda bloqueada.
  final Map<String, DateTime> _lockedUntil = {};

  static const _maxAttempts = 5;
  static const _lockoutDuration = Duration(minutes: 15);

  /// Carga las cuentas guardadas, una sola vez.
  Future<void> _ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((email, value) {
          final m = Map<String, dynamic>.from(value as Map);
          _accounts[email] = {
            for (final e in m.entries) e.key: e.value as String,
          };
        });
      }
    } catch (_) {
      // Si el almacenamiento falla o está dañado, se empieza vacío.
    }
    _ensureDemoAdmin();
  }

  /// Cuenta de administrador SOLO PARA DEMOSTRACIÓN, para poder aprobar
  /// médicos mientras no hay servidor. Con Firebase se reemplaza por un
  /// rol de administrador asignado en el servidor (nunca una contraseña
  /// escrita en el código).
  static const demoAdminEmail = 'admin@kardex.com';
  static const _demoAdminPassword = 'Admin2026!';

  void _ensureDemoAdmin() {
    if (_accounts.containsKey(demoAdminEmail)) return;
    final salt = _newSalt();
    _accounts[demoAdminEmail] = {
      'salt': salt,
      'hash': _hash(salt, _demoAdminPassword),
      'role': UserRole.administrador.name,
      'status': VerificationStatus.approved.name,
    };
  }

  static VerificationStatus _statusOf(Map<String, String>? account) {
    // Las cuentas guardadas antes de existir la verificación no tienen
    // estado: se consideran aprobadas para no dejarlas fuera.
    final raw = account?['status'];
    for (final s in VerificationStatus.values) {
      if (s.name == raw) return s;
    }
    return VerificationStatus.approved;
  }

  static ProfessionalData? _professionalOf(Map<String, String>? account) {
    if (account == null || account['license'] == null) return null;
    return ProfessionalData(
      document: account['document'] ?? '',
      license: account['license'] ?? '',
      specialty: account['specialty'] ?? '',
    );
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_accounts));
    } catch (_) {
      // Un fallo al guardar no debe romper el registro en pantalla.
    }
  }

  static String _newSalt() {
    final rnd = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => rnd.nextInt(256)));
  }

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  @override
  Future<RegisterResult> register(RegisterData data) async {
    await Future.delayed(const Duration(milliseconds: 600));
    await _ensureLoaded();

    final emailKey = data.email.trim().toLowerCase();
    if (_accounts.containsKey(emailKey)) {
      return const RegisterResult.error(
        'Ya existe una cuenta registrada con este correo electrónico',
      );
    }

    // Nadie puede registrarse como administrador desde la app.
    final role = data.role == UserRole.administrador
        ? UserRole.paciente
        : data.role;
    final isDoctor = role == UserRole.personalMedico;
    final prof = data.professional;

    final salt = _newSalt();
    _accounts[emailKey] = {
      'salt': salt,
      'hash': _hash(salt, data.password),
      'role': role.name,
      // Los médicos quedan pendientes hasta que un administrador los
      // apruebe; los demás roles no necesitan verificación.
      'status': (isDoctor
              ? VerificationStatus.pending
              : VerificationStatus.approved)
          .name,
      if (isDoctor && prof != null) ...prof.toMap(),
    };
    await _persist();
    return const RegisterResult.ok();
  }

  @override
  Future<LoginResult> login(LoginData data) async {
    await Future.delayed(const Duration(milliseconds: 600));
    await _ensureLoaded();

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

    final account = _accounts[emailKey];
    final isValid = account != null &&
        account['hash'] == _hash(account['salt']!, data.password);

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

    final roleName = account?['role'];
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => UserRole.paciente,
    );
    return LoginResult.ok(
      AppUser(
        uid: emailKey,
        email: data.email.trim(),
        role: role,
        verification: _statusOf(account),
        professional: _professionalOf(account),
      ),
    );
  }

  @override
  Future<List<DoctorRequest>> doctorRequests() async {
    await _ensureLoaded();
    return [
      for (final e in _accounts.entries)
        if (e.value['role'] == UserRole.personalMedico.name)
          DoctorRequest(
            email: e.key,
            professional: _professionalOf(e.value) ??
                const ProfessionalData(document: '', license: '', specialty: ''),
            status: _statusOf(e.value),
          ),
    ];
  }

  @override
  Future<void> setVerification(String email, VerificationStatus status) async {
    await _ensureLoaded();
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null) return;
    account['status'] = status.name;
    await _persist();
  }

  @override
  Future<VerificationStatus> verificationOf(String email) async {
    await _ensureLoaded();
    return _statusOf(_accounts[email.trim().toLowerCase()]);
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
