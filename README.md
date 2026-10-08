# Kardex — Registro e inicio de sesión (RF-01, RF-02)

Código del proyecto Flutter de Kardex: pantallas de registro e inicio
de sesión, ajustadas al mockup oficial (18 pantallas) y a la
especificación de requerimientos.

## Qué incluye esta entrega

- `lib/core/validators.dart` — validaciones de campos (correo,
  contraseña, teléfono, texto libre con máximo de caracteres, tipo de
  sangre), siguiendo RF-24. Algunos validadores (nombre, teléfono,
  tipo de sangre) están listos pero todavía sin usar: se conectarán
  cuando se construya la pantalla de perfil médico (RF-04).
- `lib/models/app_user.dart` — modelos `UserRole`, `RegisterData`,
  `LoginData`, `AppUser`, y `MedicalProfile`/`EmergencyContact` (para
  RF-04, aún no usados).
- `lib/services/auth_service.dart` — contrato `AuthService` +
  `MockAuthService` (funciona sin backend):
  - `register()`: simula "correo ya registrado" (RF-01).
  - `login()`: valida credenciales, bloquea la cuenta 15 minutos tras
    5 intentos fallidos consecutivos, y muestra un mensaje genérico de
    error sin indicar cuál campo falló (RF-02).
  - Plantilla comentada de la implementación real con Firebase.
- `lib/screens/register_screen.dart` — pantalla "Crear cuenta": correo,
  contraseña (con checklist de reglas en vivo) y rol. Coincide con el
  mockup 3.
- `lib/screens/login_screen.dart` — pantalla "Inicia sesión en tu
  cuenta": correo, contraseña, enlace de contraseña olvidada, botón de
  iniciar sesión, acceso para crear cuenta y botones de Google/Apple
  (visibles pero deshabilitados, como en el mockup 2 — se conectarán
  más adelante).
- `lib/main.dart` — arranca la app en la pantalla de inicio de sesión,
  igual que el flujo del mockup (splash → login).

## Qué cambió respecto a la primera entrega

La primera versión de `register_screen.dart` pedía nombre completo,
teléfono, confirmar contraseña y la información médica completa. El
mockup oficial (pantalla 3) muestra que el registro solo pide **correo,
contraseña y rol** — el resto se captura después, en otra pantalla
(perfil / información personal, aún no construida). Esta entrega ajusta
el registro a eso y agrega el login (RF-02), que no existía antes.

## Cómo correrlo

```bash
flutter pub get
flutter run -d chrome
```

(Si usas este código suelto sin las carpetas `android/`/`ios/`/`web/`,
genera un proyecto nuevo con `flutter create .` primero, tal como se
hizo la primera vez.)

## Siguiente paso: conectar Firebase (opcional por ahora)

Las pantallas ya funcionan con `MockAuthService`, así que no necesitas
Firebase para probarlas. Cuando quieras conectar el backend real:

1. Ejecuta `flutterfire configure` para generar `firebase_options.dart`.
2. Inicializa Firebase en `main()`.
3. Descomenta y ajusta `FirebaseAuthService` en
   `lib/services/auth_service.dart`.
4. Reemplaza `MockAuthService()` por `FirebaseAuthService()` en
   `lib/main.dart`.

## Requerimientos cubiertos

- **RF-01** — Registro de usuario (correo, contraseña, rol).
- **RF-02** — Inicio de sesión, con bloqueo tras 5 intentos fallidos.
- **RF-24** (parcial) — Validación de tipo de dato por campo: correo y
  contraseña (oculta, con `obscureText`).

Pendientes para una próxima entrega: RF-03 (navegación por rol tras
iniciar sesión), RF-04 (perfil médico, en pantalla aparte), RF-19
(recuperar contraseña, ya tiene el enlace pero falta la lógica), y el
resto de RF-24 para las demás pantallas.
