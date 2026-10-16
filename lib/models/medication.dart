/// Medicamento registrado por el paciente (RF-10, RF-21).
class Medication {
  final String id;
  final String name;
  final String dose; // texto libre, ej. '50 mg'
  final List<String> times; // horarios 'HH:mm' en 24 horas, ordenados
  final int totalDoses; // dosis disponibles en el frasco o caja (stock)
  final DateTime createdAt; // desde cuándo cuentan las dosis programadas

  const Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.times,
    required this.totalDoses,
    required this.createdAt,
  });

  int get dosesPerDay => times.length;

  /// RF-13: días restantes = dosis disponibles ÷ dosis diarias,
  /// redondeando siempre hacia abajo y sin valores negativos.
  int get daysRemaining {
    if (dosesPerDay == 0 || totalDoses <= 0) return 0;
    return totalDoses ~/ dosesPerDay;
  }

  Medication copyWith({
    String? name,
    String? dose,
    List<String>? times,
    int? totalDoses,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      times: times ?? this.times,
      totalDoses: totalDoses ?? this.totalDoses,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Estado de una toma programada del día.
enum DoseStatus { pending, taken, missed }

/// Una toma concreta (medicamento + hora de hoy) con su estado.
class ScheduledDose {
  final Medication medication;
  final DateTime scheduled;
  final DoseStatus status;

  const ScheduledDose({
    required this.medication,
    required this.scheduled,
    required this.status,
  });
}

/// Toma confirmada, guardada para el historial (RF-15).
class DoseLog {
  final String medicationId;
  final String medicationName;
  final String dose;
  final DateTime scheduled;
  final DateTime takenAt;

  const DoseLog({
    required this.medicationId,
    required this.medicationName,
    required this.dose,
    required this.scheduled,
    required this.takenAt,
  });
}

/// Fila del historial de tomas: confirmada u omitida (RF-15).
class HistoryEntry {
  final String medicationName;
  final String dose;
  final DateTime scheduled;
  final DoseStatus status; // solo taken o missed

  const HistoryEntry({
    required this.medicationName,
    required this.dose,
    required this.scheduled,
    required this.status,
  });
}
