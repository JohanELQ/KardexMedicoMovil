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
  fondo oscuro, ícono de corazón, título "Kardex", "Bienvenido a
  Kardex" y el tagline. Pasa automáticamente al login después de 2
  segundos (o al tocar la pantalla).
- `lib/screens/forgot_password_screen.dart` — recuperación de
  contraseña (RF-19): pide el correo y, sin importar si existe o no en
  el sistema, siempre muestra el mismo mensaje de confirmación ("Si el
  correo está registrado, te enviamos un enlace..."), tal como exige el
  requerimiento. Se accede desde "¿Olvidaste tu contraseña?" en el
  login.
- **Inicio del paciente (mockups 5, 7, 8, 13, 14, 15, 16)** — ahora
  funciona con datos reales creados por el usuario (guardados en el
  dispositivo):
  - `patient_home_screen.dart` — contenedor con las pestañas Inicio,
    Medicamentos y Perfil, que comparten un mismo `PatientStore`.
  - `patient_home_tab.dart` — saludo, tarjeta del QR (aparece cuando
    hay perfil médico) y próximas dosis de hoy; tocar una dosis
    pendiente la confirma (RF-12).
  - `medications_tab.dart` + `add_medication_screen.dart` — lista,
    alta, edición y eliminación de medicamentos (RF-10, RF-21), con
    días restantes (RF-13) y confirmación de toma.
  - `medical_profile_screen.dart` — ver y editar el perfil médico
    (RF-04, RF-05); cada guardado genera un QR nuevo (RF-06).
  - `qr_screen.dart` — QR de emergencia en grande (mockup 8).
  - `history_screen.dart` — historial de tomas confirmadas y omitidas
    (RF-15).
  - `profile_tab.dart` — accesos y cierre de sesión (RF-20).
  - `lib/services/patient_store.dart` — almacén en memoria (perfil,
    medicamentos, historial). Cuando se conecte `sqflite`/Firestore,
    solo cambia el interior de este archivo.
  - `lib/models/medication.dart`, `lib/core/format.dart` — modelos y
    utilidades de formato.
- **Personal médico (mockups 6 y 9, RF-07, RF-08, RF-09)**:
  - `scan_patient_qr_screen.dart` — escáner con cámara (diseño y
    cámara de JohanELQ, rama `feature/funcion-scaner-QR`), conectado
    con la búsqueda real del perfil. Si el código no es legible o no
    corresponde a un perfil, pide intentar de nuevo. El ícono de
    teclado permite pegar el código a mano.
  - `emergency_view_screen.dart` — vista de emergencia de solo
    lectura: nombre, edad, tipo de sangre, alergias, condiciones,
    medicamentos con dosis y horarios (o «Sin medicamentos
    registrados») y contacto. No tiene botones para editar nada.
  - `lib/services/emergency_lookup.dart` — busca el perfil que
    corresponde al código. Por ahora busca entre los pacientes
    guardados en el mismo dispositivo; con Firestore solo cambia este
    archivo.
  - El QR lleva un identificador opaco (no el correo) y un token que
    cambia con cada guardado del perfil: un QR viejo deja de ser válido
    (RF-06, RNF-01).
- **Inicio del personal médico completo (mockup 6, RF-03, RF-20)** —
  `medical_staff_home_screen.dart` con tres pestañas:
  - Inicio: tarjeta para escanear y accesos rápidos con contadores.
  - Pacientes (`staff_patients_tab.dart`): pacientes ya escaneados,
    con fecha del último escaneo; tocar uno abre su ficha.
  - Perfil (`staff_profile_tab.dart`): cuenta, historial y cierre de
    sesión.
  - `scan_history_screen.dart` + `lib/services/scan_history_store.dart`:
    historial de escaneos guardado en el dispositivo. Solo guarda el
    nombre, el tipo de sangre y el código; los datos clínicos se
    consultan de nuevo cada vez (RNF-01). Si el paciente actualizó su
    perfil, su QR cambió y hay que escanearlo otra vez (RF-06).
- **Notificaciones dentro de la app (campana)** — `notification_store.dart`
  y `notifications_screen.dart`, para paciente y médico:
  - Paciente: recordatorio de toma, medicamento por agotarse (RF-14,
    umbral configurable de 1 a 10 días, un aviso por día) y «Tu perfil
    médico fue consultado» cuando un médico escanea su QR (RNF-08).
  - Médico: cuenta aprobada o rechazada.
  - Son avisos dentro de la app. Las notificaciones del sistema con la
    app cerrada (RF-11) llegan con flutter_local_notifications en
    Android.
- **Verificación de médicos** — al registrarse como personal médico se
  piden documento, registro médico y especialidad. La cuenta queda
  *pendiente* y no puede escanear ni ver pacientes hasta que un
  administrador la apruebe (`staff_verification_screen.dart`,
  `admin_home_screen.dart`). Es una verificación manual por un
  administrador: comprobar el registro contra el ReTHUS del Ministerio
  de Salud necesita un servidor y queda para cuando se conecte Firebase.
  Para demostración existe la cuenta `admin@kardex.com` (su contraseña
  está en `auth_service.dart`; con Firebase se reemplaza por un rol de
  administrador asignado en el servidor). Las cuentas de médico creadas
  antes de esta función se consideran aprobadas.
- **Recordatorio de medicamentos (mockup 10, RF-11)** —
  `medication_reminder.dart`: cuando llega la hora de una toma (revisión
  cada 10 segundos, desvío menor a 1 minuto) aparece a pantalla completa
  con el nombre y la dosis, y los botones «Confirmar» (descuenta stock y
  guarda en el historial) y «Posponer» (vuelve a avisar en 10 minutos;
  la X también pospone). Por ahora solo con la app abierta.
- Login: checkbox "Recordarme" (guarda solo el correo, nunca la
  contraseña). Requiere el paquete `shared_preferences`.
- `lib/main.dart` — arranca la app en el splash, igual que el flujo del
  mockup (splash → login → bienvenida → inicio según el rol).

### Limitaciones actuales del inicio del paciente

- Las cuentas y los datos del paciente se guardan en el dispositivo
  (`shared_preferences`), no en un servidor: cada navegador o celular
  tiene sus propios datos. La contraseña se guarda como hash con sal,
  nunca en texto. Cuando se conecte Firebase, esto pasa al servidor.
  Requiere el paquete `crypto`.
- En Chrome los datos se guardan por dirección (puerto). Para no
  perderlos entre ejecuciones, usar `flutter run -d chrome --web-port=5000`.
- Los recordatorios solo salen con la app abierta. Las notificaciones
  reales con la app cerrada (RF-11) y el aviso de medicamento por
  agotarse (RF-14) necesitan flutter_local_notifications en Android.
- Una toma sin confirmar pasa a "omitida" después de 2 horas, pero la
  pantalla solo recalcula el estado cuando se vuelve a dibujar.

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
- **RF-19** — Recuperación de contraseña: solicita el correo y nunca
  revela si existe o no una cuenta asociada.
- **RF-04, RF-05, RF-06** — Perfil médico, edición y QR que se
  regenera con cada guardado (el QR usa un identificador de ejemplo,
  todavía sin cifrado real ni base de datos compartida).
- **RF-10, RF-12, RF-13, RF-15, RF-21** — Medicamentos, confirmación de
  toma con descuento de stock, días restantes, historial y
  edición/eliminación.
- **RF-07, RF-08, RF-09** — Escaneo del QR y vista de emergencia de
  solo lectura con medicamentos (funciona entre usuarios del mismo
  dispositivo hasta conectar una base compartida).
- **RF-20** — Cierre de sesión.
- **RF-24** (parcial) — Validación de tipo de dato por campo: correo,
  contraseña, teléfono y cantidad de dosis (solo dígitos), y textos
  con límite de caracteres.

Pendientes para una próxima entrega: RF-11/RF-14 (notificaciones
de tomas y stock bajo), RF-16 a RF-18 (geofencing), RF-22 (permisos),
RF-23 (varios contactos de emergencia), almacenamiento persistente
(RNF-02) y Firebase.

## Geofencing de farmacias (RF-16/17/18)

- Lógica base de JohanELQ (`pharmacy_geofencing.dart`), integrada en `lib/services/pharmacy_geofencing.dart`.
- Avisa solo si al paciente le queda poco de un medicamento (umbral de RF-14) y está a menos de 300 m de una farmacia, una vez por farmacia cada 24 h.
- Se activa en Notificaciones ("Avisarme cerca de una farmacia"), pide permiso de ubicación y revisa cada 2 min con la app abierta.
- Hay un botón "Probar aviso de farmacia" para la demostración.
- Limitaciones: lista de farmacias fija en `lib/core/pharmacies.dart` (ejemplo en Cali); no usa la API de Geofencing de Google ni funciona con la app cerrada (RNF-05 pendiente).

## Permisos y modo sin conexión (mockups 17 y 18, RF-22)

- `permissions_screen.dart`: estado de cámara, ubicación y notificaciones, con interruptores (pide el permiso o abre los ajustes del celular). En el navegador solo muestra una nota, porque ahí los permisos se manejan desde el candado de la barra de direcciones.
- `offline_mode_screen.dart`: pantalla informativa. Los datos ya se guardan en el dispositivo; la sincronización en la nube sigue pendiente (Firebase).
- Se abren desde Perfil.
