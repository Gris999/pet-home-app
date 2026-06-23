class PetImageAnalysis {
  const PetImageAnalysis({
    required this.id,
    required this.petId,
    required this.petName,
    required this.imageUrl,
    required this.imageQuality,
    required this.visibleObservations,
    required this.generalRecommendations,
    required this.attentionLevel,
    required this.requiresConsultation,
    required this.preventiveMessage,
    required this.status,
    this.errorMessage,
    this.createdAt,
  });

  final int id;
  final int petId;
  final String petName;
  final String imageUrl;
  final String imageQuality;
  final List<String> visibleObservations;
  final List<String> generalRecommendations;
  final String attentionLevel;
  final bool requiresConsultation;
  final String preventiveMessage;
  final String status;
  final String? errorMessage;
  final DateTime? createdAt;

  factory PetImageAnalysis.fromJson(Map<String, dynamic> json) {
    return PetImageAnalysis(
      id: _asInt(json['id_analisis_imagen']),
      petId: _asInt(json['mascota']),
      petName: (json['mascota_nombre'] ?? 'Mascota').toString(),
      imageUrl: (json['imagen_url'] ?? '').toString(),
      imageQuality: (json['calidad_imagen'] ?? 'NO_ANALIZABLE').toString(),
      visibleObservations: _asStringList(json['observaciones_visibles']),
      generalRecommendations: _asStringList(json['recomendaciones_generales']),
      attentionLevel: (json['nivel_atencion'] ?? 'NO_ANALIZABLE').toString(),
      requiresConsultation: json['requiere_consulta'] == true,
      preventiveMessage: (json['mensaje_preventivo'] ?? '').toString(),
      status: (json['estado'] ?? '').toString(),
      errorMessage: json['error_mensaje']?.toString(),
      createdAt: _asDateTime(json['fecha_creacion']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String && value.trim().isNotEmpty) return [value.trim()];
  return <String>[];
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
