class ChatbotResponse {
  ChatbotResponse({
    required this.message,
    required this.ok,
    required this.action,
    required this.data,
    required this.options,
    this.context,
  });

  final String message;
  final bool ok;
  final String? action;
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> options;
  final Map<String, dynamic>? context;

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['opciones'];
    return ChatbotResponse(
      message: (json['respuesta'] ?? json['message'] ?? '').toString(),
      ok: json['ok'] == true,
      action: json['accion']?.toString(),
      data: (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      options: rawOptions is List
          ? rawOptions.whereType<Map<String, dynamic>>().toList(growable: false)
          : const <Map<String, dynamic>>[],
      context: json['contexto'] as Map<String, dynamic>?,
    );
  }
}
