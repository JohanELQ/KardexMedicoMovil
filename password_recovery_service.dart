import 'package:firebase_auth/firebase_auth.dart';

/// RF-19: envío de correo de recuperación mediante Firebase Authentication.
class PasswordRecoveryService {
  PasswordRecoveryService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Devuelve un mensaje neutral para no revelar si el correo está registrado.
  Future<void> sendRecoveryEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
