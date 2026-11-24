# Kardex — Perfil médico de emergencia con QR y recordatorio de medicamentos

Aplicación móvil hecha en **Flutter (Dart)**. Cada paciente guarda su perfil
médico y sus medicamentos; el personal médico escanea su código QR y ve la
información de emergencia sin que el paciente tenga que desbloquear nada.
La app avisa cuándo tomar cada medicamento, cuándo se está acabando y cuándo
el paciente pasa cerca de una farmacia.

Proyecto de un curso universitario. Equipo: Santiago Balanta y JohanELQ.

## Qué hace

- **Cuentas y roles:** registro, inicio de sesión, «Recordarme», recuperación
  de contraseña. Roles paciente, personal médico y administrador. Los médicos
  los aprueba un administrador.
- **Paciente:** perfil médico (tipo de sangre, alergias, condiciones), hasta 5
  contactos de emergencia con interruptor de visibilidad, código QR que cambia
  al editar el perfil, medicamentos con horarios y stock, historial de tomas.
- **Personal médico:** escanea el QR y ve la ficha de emergencia en solo
  lectura (datos, medicamentos y contactos visibles). Guarda un historial de
  escaneos.
- **Notificaciones con la app cerrada (Android):** recordatorio de cada toma
  con botones «Confirmar toma» y «Posponer», y aviso de medicamento por
  agotarse.
- **Farmacias:** el paciente registra farmacias (nombre, dirección,
  coordenadas, radio de 150 m por defecto). Si le queda poco de un
  medicamento y entra al radio de una, recibe un aviso aunque la app esté
  cerrada (Geofencing API de Google Play Services).
- **Accesibilidad:** tamaño de letra ajustable (Perfil → Accesibilidad) y
  contraste de texto de al menos 4.5:1.
- **Errores claros:** mensajes de datos inválidos, de conexión y de reglas de
  negocio que dicen qué pasó y cómo corregirlo.

## Estado de los requerimientos

| Requerimiento | Estado |
|---|---|
| RF-01 a RF-03 Registro, inicio de sesión y roles | Hecho. La unicidad del correo se comprueba solo en el dispositivo (no hay servidor) |
| RF-04 a RF-06 Perfil médico y QR | Hecho |
| RF-07 a RF-09 Escaneo y acceso de emergencia | Hecho |
| RF-10 a RF-15 Medicamentos, notificaciones y historial | Hecho (notificaciones solo en Android) |
| RF-16 a RF-18 Farmacias y geofencing | Hecho en Android, también con la app cerrada. No hay versión para iPhone |
| RF-19 Recuperación de contraseña | Flujo completo con el mensaje genérico exigido. El envío del correo es simulado: no hay servidor |
| RF-20 a RF-22 Cierre de sesión, edición de medicamentos, permisos | Hecho |
| RF-23 Contactos de emergencia visibles | Hecho |
| RF-24 y RF-25 Validación y mensajes de error | Hecho |
| RNF-01 Seguridad | Contraseñas con hash y sal. HTTPS no aplica todavía (sin servidor) |
| RNF-02 Disponibilidad sin conexión | Hecho: los datos se guardan en el dispositivo (`shared_preferences`, no SQLite) |
| RNF-03 a RNF-06 | Implementados. Las mediciones están en `docs/pruebas_rnf.md` |
| RNF-07 Android 9+ y ubicación en segundo plano | Hecho |
| RNF-08 Privacidad y RNF-09 Accesibilidad | Hecho |

## Instalar la APK en un celular Android

1. Pasa el archivo `app-release.apk` al celular (WhatsApp, Drive o cable USB).
2. Si ya tenías Kardex instalado, desinstálalo antes.
3. Ábrelo y presiona **Instalar**. En Samsung, si sale «Aplicaciones
   desconocidas bloqueadas», desactiva temporalmente *Ajustes → Seguridad y
   privacidad → Bloqueador automático* y vuelve a activarlo al terminar.
4. Al abrir la app, acepta el permiso de notificaciones. Para los avisos de
   farmacia con la app cerrada, en *Notificaciones* activa los avisos y elige
   **«Permitir todo el tiempo»** en Ubicación.

## Ejecutar y compilar desde el código

Requisitos: Flutter 3.47 o superior y, para Android, el SDK de Android.

```
flutter pub get
flutter run -d chrome --web-port=5000      # en el navegador (sin notificaciones)
flutter build apk --release                # APK en build/app/outputs/flutter-apk/
flutter analyze
flutter test
```

Cuentas de demostración: el administrador es `admin@kardex.com` con la
contraseña `Admin2026!`. Los demás usuarios se crean desde «Crear cuenta».

## Estructura

- `lib/core/` — validadores, formato, manejo central de errores, farmacias de ejemplo.
- `lib/models/` — usuario, perfil médico, medicamento.
- `lib/services/` — autenticación, almacenamiento local, notificaciones del
  sistema, geofencing en primer y segundo plano, planificadores de avisos.
- `lib/screens/` — todas las pantallas.
- `docs/pruebas_rnf.md` — casos de prueba de los requerimientos no funcionales.
- `docs/historial_entregas.md` — detalle de cada entrega anterior.

## Flujo de ramas (Git Flow)

`feature/*` → `develop` → `QA` → `main`. Cada funcionalidad se trabaja en su
rama y entra por pull request con revisión.

## Limitaciones conocidas

- Los datos viven en cada celular: médico y paciente solo se ven en el mismo
  dispositivo. Compartirlos entre dispositivos necesita un servidor (Firebase).
- No hay correo real de recuperación ni unicidad de cuentas entre
  dispositivos, por la misma razón.
- Solo Android. Para iPhone hacen falta un Mac, Xcode y una cuenta de Apple
  Developer.
- En algunos celulares (por ejemplo Samsung) el ahorro de batería puede
  retrasar las alarmas; conviene quitar la restricción de batería a Kardex.
