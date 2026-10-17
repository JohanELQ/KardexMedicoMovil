/// Utilidades pequeñas de formato (horas, fechas, textos de días).
/// Se escriben a mano para no depender del paquete `intl`.

const List<String> _monthsEs = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String two(int n) => n.toString().padLeft(2, '0');

/// 'HH:mm' (24 horas) -> [hora, minuto].
List<int> parseHm(String value) {
  final parts = value.split(':');
  return [int.parse(parts[0]), int.parse(parts[1])];
}

/// (8, 5) -> '08:05' (24 horas, formato en que se guardan los horarios).
String formatHm(int hour, int minute) => '${two(hour)}:${two(minute)}';

/// (20, 0) -> '08:00 PM' (formato que se muestra en pantalla).
String formatTime12(int hour, int minute) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '${two(h12)}:${two(minute)} $period';
}

/// '20:00' -> '08:00 PM'.
String formatHm12(String value) {
  final p = parseHm(value);
  return formatTime12(p[0], p[1]);
}

/// 'Hoy', 'Ayer' o '25 sep 2026'.
String dayLabel(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  return '${d.day} ${_monthsEs[d.month - 1]} ${d.year}';
}

/// RF-13: 'Quedan 6 días', 'Queda 1 día' o '0 días'.
String daysRemainingText(int days) {
  if (days <= 0) return '0 días';
  if (days == 1) return 'Queda 1 día';
  return 'Quedan $days días';
}

/// Frecuencia legible según las tomas por día: 2 -> 'Cada 12 horas',
/// 3 -> 'Cada 8 horas'. Si 24 no se divide exacto, '5 tomas al día'.
String everyHoursText(int dosesPerDay) {
  if (dosesPerDay <= 0) return 'Sin horarios';
  if (24 % dosesPerDay == 0) return 'Cada ${24 ~/ dosesPerDay} horas';
  return '$dosesPerDay tomas al día';
}

/// Nombre provisional a partir del correo (hasta que exista la pantalla
/// de información personal): 'juan@correo.com' -> 'juan'.
String nameFromEmail(String email) {
  final at = email.indexOf('@');
  return at > 0 ? email.substring(0, at) : email;
}
