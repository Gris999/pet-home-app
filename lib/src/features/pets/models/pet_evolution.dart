class PetEvolutionRecord {
  const PetEvolutionRecord({
    required this.id,
    required this.petId,
    required this.weight,
    required this.bodyCondition,
    required this.bodyConditionDisplay,
    required this.recordDate,
    this.petName,
    this.note,
  });

  final int id;
  final int petId;
  final String? petName;
  final double weight;
  final String bodyCondition;
  final String bodyConditionDisplay;
  final String? note;
  final DateTime? recordDate;

  factory PetEvolutionRecord.fromJson(Map<String, dynamic> json) {
    return PetEvolutionRecord(
      id: _asInt(json['id_registro']),
      petId: _asInt(json['mascota']),
      petName: _asNullableString(json['mascota_nombre']),
      weight: _asDouble(json['peso']),
      bodyCondition: _asString(json['condicion_corporal'], fallback: 'NO_EVALUADO'),
      bodyConditionDisplay: _asString(
        json['condicion_corporal_display'],
        fallback: 'No evaluado',
      ),
      note: _asNullableString(json['nota']),
      recordDate: _asDate(json['fecha_registro']),
    );
  }
}

class PetEvolutionRequest {
  const PetEvolutionRequest({
    required this.weight,
    required this.bodyCondition,
    required this.recordDate,
    this.note,
  });

  final double weight;
  final String bodyCondition;
  final DateTime recordDate;
  final String? note;

  Map<String, dynamic> toJson() => {
        'peso': weight.toStringAsFixed(2),
        'condicion_corporal': bodyCondition,
        'nota': note,
        'fecha_registro': _formatDate(recordDate),
      };
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime? _asDate(dynamic value) {
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

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  return 0;
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return fallback;
  return text;
}

String? _asNullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}
