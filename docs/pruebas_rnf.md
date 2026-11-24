# Pruebas de los requerimientos no funcionales (Kardex)

Un caso de prueba por cada RNF, como pide la sección 3 del documento de
requerimientos. La columna **Resultado** se llena al probar en el celular
(Samsung Galaxy A37, Android 16). «Pendiente» = aún sin medir.

| RNF | Qué se prueba | Cómo se prueba | Criterio | Resultado |
|---|---|---|---|---|
| RNF-01 Seguridad | Contraseñas cifradas; el QR solo expone lo necesario | Revisar que las contraseñas se guardan con hash y sal (no en texto) y que el QR contiene solo `KARDEX-EMERGENCIA:<id>:<token>` | Sin contraseñas en claro; QR sin datos médicos | Cumple (hash + sal; el token del QR cambia al guardar el perfil). HTTPS no aplica: aún no hay servidor |
| RNF-02 Disponibilidad | Consultar perfil y QR sin internet | Activar modo avión, abrir la app, entrar al perfil médico y al QR | Se ven sin conexión | Pendiente (esperado: cumple, los datos están en el dispositivo) |
| RNF-03 Rendimiento | Tiempo para ver la información tras escanear el QR | Cronometrar desde que la cámara lee el QR hasta que aparece la ficha de emergencia (3 intentos) | Menos de 5 s | Pendiente |
| RNF-04 Confiabilidad | Desvío de la notificación de medicamento | Programar un medicamento a una hora exacta, cerrar la app y anotar a qué hora llega | Desvío menor de 1 minuto, también sin conexión | Pendiente |
| RNF-05 Eficiencia energética | Geofencing sin GPS continuo | Las farmacias se registran en la Geofencing API de Google Play Services (`native_geofence`); revisar en Ajustes → Batería el consumo de Kardex tras un día | Uso de la Geofencing API, sin GPS activo todo el tiempo | Implementado; consumo en batería pendiente de medir |
| RNF-06 Usabilidad | Pasos para registrar un medicamento y tiempo del perfil inicial | Contar los pasos: Medicamentos → «+» → llenar → Guardar. Cronometrar el perfil médico inicial | Medicamento en 4 pasos o menos; perfil en menos de 5 min | Pendiente (esperado: 4 pasos) |
| RNF-07 Compatibilidad | Android 9+ y ubicación en segundo plano en Android 10+ | Instalar la APK; activar «Permitir todo el tiempo» en Ubicación; cerrar la app y comprobar el aviso de farmacia | Funciona; permisos de ubicación en segundo plano declarados | Probado en Android 16 (API 36); permiso `ACCESS_BACKGROUND_LOCATION` declarado |
| RNF-08 Privacidad | Elegir qué contactos se ven en emergencia | Perfil médico → 2 contactos → ocultar uno → escanear el QR | Solo se muestra el contacto visible; no se puede ocultar el último | Cumple (RF-23) |
| RNF-09 Accesibilidad | Tamaño de letra y contraste | Perfil → Accesibilidad → «Muy grande»; revisar contraste de los textos | Letra ajustable; contraste mínimo 4.5:1 | Cumple (ver tabla de contraste) |

## Contraste de texto sobre fondo blanco (RNF-09)

| Uso | Color | Relación | ¿≥ 4.5:1? |
|---|---|---|---|
| Texto secundario | gris 600 `#757575` | 4.61:1 | Sí |
| Texto de ayuda | gris 700 `#616161` | 6.19:1 | Sí |
| Mensajes de error | error del tema `#BA1A1A` | 6.46:1 | Sí |
| Opción «Cerrar sesión» (personal médico) | rojo 800 `#C62828` | 5.62:1 | Sí |
| Texto de error anterior | rojo 500 `#F44336` | 3.68:1 | No (se reemplazó) |

Los iconos decorativos en gris 500 (2.68:1) no son texto; el criterio de
4.5:1 aplica al texto.

## Cómo llenar los resultados pendientes

1. RNF-02: modo avión, abrir perfil y QR.
2. RNF-03: cronometrar el escaneo 3 veces y anotar el promedio.
3. RNF-04: programar una toma y anotar la hora exacta de llegada.
4. RNF-06: contar los pasos y cronometrar el perfil inicial.
5. RNF-05: anotar el consumo de batería de Kardex después de un día.
