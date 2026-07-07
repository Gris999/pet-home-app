class PetDigitalCard {
  const PetDigitalCard({
    required this.pet,
    required this.owner,
    required this.veterinary,
    required this.vaccines,
    required this.historySummary,
    required this.pendingPlan,
    required this.qrPayload,
    this.qrUrl,
  });

  final DigitalPet pet;
  final DigitalOwner owner;
  final DigitalVeterinary veterinary;
  final List<DigitalVaccine> vaccines;
  final DigitalHistorySummary historySummary;
  final List<DigitalPendingPlan> pendingPlan;
  final String qrPayload;
  final String? qrUrl;

  factory PetDigitalCard.fromJson(Map<String, dynamic> json) {
    return PetDigitalCard(
      pet: DigitalPet.fromJson(_asMap(json['mascota'])),
      owner: DigitalOwner.fromJson(_asMap(json['duenio'])),
      veterinary: DigitalVeterinary.fromJson(_asMap(json['veterinaria'])),
      vaccines: _asList(json['vacunas_aplicadas'])
          .whereType<Map<String, dynamic>>()
          .map(DigitalVaccine.fromJson)
          .toList(),
      historySummary: DigitalHistorySummary.fromJson(_asMap(json['historial_resumen'])),
      pendingPlan: _asList(json['plan_sanitario_pendiente'])
          .whereType<Map<String, dynamic>>()
          .map(DigitalPendingPlan.fromJson)
          .toList(),
      qrPayload: _asString(json['qr_payload']),
      qrUrl: _asNullableString(json['qr_url']),
    );
  }
}

class DigitalPet {
  const DigitalPet({
    required this.id,
    required this.name,
    this.species,
    this.breed,
    this.sex,
    this.birthDate,
    this.color,
    this.weight,
    this.size,
    this.photo,
    this.allergies,
    this.notes,
  });

  final int id;
  final String name;
  final String? species;
  final String? breed;
  final String? sex;
  final String? birthDate;
  final String? color;
  final String? weight;
  final String? size;
  final String? photo;
  final String? allergies;
  final String? notes;

  factory DigitalPet.fromJson(Map<String, dynamic> json) {
    return DigitalPet(
      id: _asInt(json['id_mascota']),
      name: _asString(json['nombre'], fallback: 'Mascota'),
      species: _asNullableString(json['especie']),
      breed: _asNullableString(json['raza']),
      sex: _asNullableString(json['sexo']),
      birthDate: _asNullableString(json['fecha_nac']),
      color: _asNullableString(json['color']),
      weight: _asNullableString(json['peso']),
      size: _asNullableString(json['tamano']),
      photo: _asNullableString(json['foto']),
      allergies: _asNullableString(json['alergias']),
      notes: _asNullableString(json['notas_generales']),
    );
  }
}

class DigitalOwner {
  const DigitalOwner({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;

  factory DigitalOwner.fromJson(Map<String, dynamic> json) {
    return DigitalOwner(
      id: _asInt(json['id_usuario']),
      name: _asString(json['nombre'], fallback: 'Duenio'),
      email: _asNullableString(json['correo']),
      phone: _asNullableString(json['telefono']),
    );
  }
}

class DigitalVeterinary {
  const DigitalVeterinary({
    required this.id,
    required this.name,
    this.slug,
  });

  final int id;
  final String name;
  final String? slug;

  factory DigitalVeterinary.fromJson(Map<String, dynamic> json) {
    return DigitalVeterinary(
      id: _asInt(json['id_veterinaria']),
      name: _asString(json['nombre'], fallback: 'Veterinaria'),
      slug: _asNullableString(json['slug']),
    );
  }
}

class DigitalVaccine {
  const DigitalVaccine({
    required this.name,
    this.dose,
    this.appliedDate,
    this.nextDate,
    this.status,
  });

  final String name;
  final String? dose;
  final String? appliedDate;
  final String? nextDate;
  final String? status;

  factory DigitalVaccine.fromJson(Map<String, dynamic> json) {
    return DigitalVaccine(
      name: _asString(json['nombre_vacuna'], fallback: 'Vacuna'),
      dose: _asNullableString(json['dosis']),
      appliedDate: _asNullableString(json['fecha_aplicada']),
      nextDate: _asNullableString(json['fecha_proxima']),
      status: _asNullableString(json['estado_vacuna']),
    );
  }
}

class DigitalHistorySummary {
  const DigitalHistorySummary({
    required this.hasHistory,
    required this.totalConsultations,
    this.lastConsultation,
    this.generalObservations,
  });

  final bool hasHistory;
  final int totalConsultations;
  final String? lastConsultation;
  final String? generalObservations;

  factory DigitalHistorySummary.fromJson(Map<String, dynamic> json) {
    return DigitalHistorySummary(
      hasHistory: _asBool(json['tiene_historial']),
      totalConsultations: _asInt(json['total_consultas']),
      lastConsultation: _asNullableString(json['ultima_consulta']),
      generalObservations: _asNullableString(json['observaciones_generales']),
    );
  }
}

class DigitalPendingPlan {
  const DigitalPendingPlan({
    required this.description,
    required this.typeDisplay,
    this.scheduledDate,
  });

  final String description;
  final String typeDisplay;
  final String? scheduledDate;

  factory DigitalPendingPlan.fromJson(Map<String, dynamic> json) {
    return DigitalPendingPlan(
      description: _asString(json['descripcion'], fallback: 'Cuidado pendiente'),
      typeDisplay: _asString(json['tipo_evento_display'], fallback: 'Evento'),
      scheduledDate: _asNullableString(json['fecha_programada']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  return value is List ? value : const <dynamic>[];
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
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

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'si';
  }
  return false;
}
