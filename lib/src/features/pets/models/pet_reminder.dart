class PetReminder {
  const PetReminder({
    required this.id,
    required this.petId,
    required this.type,
    required this.typeDisplay,
    required this.title,
    required this.scheduledDate,
    required this.status,
    required this.statusDisplay,
    required this.notify,
    required this.daysBefore,
    this.petName,
    this.description,
    this.scheduledTime,
  });

  final int id;
  final int petId;
  final String? petName;
  final String type;
  final String typeDisplay;
  final String title;
  final String? description;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final String status;
  final String statusDisplay;
  final bool notify;
  final int daysBefore;

  factory PetReminder.fromJson(Map<String, dynamic> json) {
    return PetReminder(
      id: _asInt(json['id_recordatorio']),
      petId: _asInt(json['mascota']),
      petName: _asNullableString(json['mascota_nombre']),
      type: _asString(json['tipo'], fallback: 'OTRO'),
      typeDisplay: _asString(json['tipo_display'], fallback: 'Otro'),
      title: _asString(json['titulo'], fallback: 'Recordatorio'),
      description: _asNullableString(json['descripcion']),
      scheduledDate: _parseDate(json['fecha_programada']),
      scheduledTime: _asNullableString(json['hora_programada']),
      status: _asString(json['estado'], fallback: 'PENDIENTE'),
      statusDisplay: _asString(json['estado_display'], fallback: 'Pendiente'),
      notify: _asBool(json['notificar'], fallback: true),
      daysBefore: _asInt(json['dias_anticipacion']),
    );
  }
}

class PetReminderRequest {
  const PetReminderRequest({
    required this.type,
    required this.title,
    required this.scheduledDate,
    this.description,
    this.scheduledTime,
    this.notify = true,
    this.daysBefore = 1,
  });

  final String type;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final bool notify;
  final int daysBefore;

  Map<String, dynamic> toJson() => {
        'tipo': type,
        'titulo': title,
        'descripcion': description,
        'fecha_programada': _formatDate(scheduledDate),
        'hora_programada': scheduledTime,
        'notificar': notify,
        'dias_anticipacion': daysBefore,
      };
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime? _parseDate(dynamic value) {
  final text = _asNullableString(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

String? _asNullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'si') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}
