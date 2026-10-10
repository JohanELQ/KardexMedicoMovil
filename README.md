# Kardex — Registro, inicio de sesión y navegación por rol (RF-01, RF-02, RF-03)

Código del proyecto Flutter de Kardex: pantallas de registro, inicio de
sesión y las pantallas de inicio según el rol, ajustadas al mockup
oficial (18 pantallas) y a la especificación de requerimientos.

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
    error sin indicar cuál campo falló (RF-02). Si el login es exitoso,
    devuelve un `AppUser` con el rol guardado en el registro.
- `lib/screens/register_screen.dart` — pantalla "Crear cuenta": correo,
  contraseña (con checklist de reglas en vivo) y rol. Coincide con el
  mockup 3.
- `lib/screens/login_screen.dart` — pantalla "Inicia sesión en tu
  cuenta": correo, contraseña, enlace de contraseña olvidada, botón de
  iniciar sesión, acceso para crear cuenta y botones de Google/Apple
  (visibles pero deshabilitados, como en el mockup 2). Al iniciar
  sesión con éxito, navega a `WelcomeScreen`.
- `lib/screens/welcome_screen.dart` — pantalla "¡Bienvenido!" (mockup
  4). Muestra las dos tarjetas de rol, pero **solo la que coincide con
  el rol real del usuario está habilitada**: la otra aparece
  deshabilitada, para cumplir RF-03 ("no debe permitir, bajo ninguna
  circunstancia, que un usuario acceda a las funciones del rol
  contrario").
- `lib/screens/patient_home_screen.dart` — inicio del paciente (mockup
  5): tarjeta de código QR de emergencia (generado con `qr_flutter`
  a partir de un identificador de ejemplo — el QR real con datos
  cifrados del perfil se construye en RF-06), lista de "próximas
  dosis" con datos de ejemplo (se conecta a datos reales en RF-10 a
  RF-13) y barra de navegación inferior.
- `lib/screens/medical_staff_home_screen.dart` — inicio del personal
  médico (mockup 6): tarjeta "Escanear código QR" (el escaneo real con
  `mobile_scanner` se conecta en RF-07) y accesos rápidos.
- `lib/screens/splash_screen.dart` — pantalla de inicio (mockup 1):
  fondo oscuro, ícono de corazón, título "Kardex" y el tagline. Pasa
  automáticamente al login después de 2 segundos (o al tocar la
  pantalla).
- `lib/main.dart` — arranca la app en el splash, igual que el flujo del
  mockup (splash → login → bienvenida → inicio según el rol).

## Qué cambió respecto a la primera entrega

La primera versión de `register_screen.dart` pedía nombre completo,
teléfono, confirmar contraseña y la información médica completa. El
mockup oficial (pantalla 3) muestra que el registro solo pide **correo,
contraseña y rol** — el resto se captura después, en otra pantalla
(perfil / información personal, aún no construida). Esa entrega ajustó
el registro a eso y agregó el login (RF-02). Esta entrega agrega RF-03:
la navegación automática según el rol después de iniciar sesión.

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
- **RF-03** — Navegación según el rol tras iniciar sesión, sin permitir
  acceso a las funciones del rol contrario.
- **RF-24** (parcial) — Validación de tipo de dato por campo: correo y
  contraseña (oculta, con `obscureText`).

Pendientes para una próxima entrega: RF-04 (perfil médico, en pantalla
aparte), RF-06/RF-07 (QR real y escaneo real), RF-10 a RF-13
(medicamentos reales), RF-19 (recuperar contraseña, ya tiene el enlace
pero falta la lógica), y el resto de RF-24 para las demás pantallas.
