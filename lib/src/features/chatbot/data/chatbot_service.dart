import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_service.dart';
import '../domain/chatbot_response.dart';

class ChatbotService {
  ChatbotService({
    AuthService? authService,
    http.Client? client,
  }) : _apiClient = ApiClient(
          authService: authService ?? AuthService(),
          client: client,
        );

  final ApiClient _apiClient;

  Future<ChatbotResponse> sendMessage({
    required String message,
    Map<String, dynamic>? context,
  }) async {
    final response = await _apiClient.send(
      method: 'POST',
      path: '/api/gestion/servicios/bot/chat/',
      body: {
        'mensaje': message,
        'contexto': context ?? <String, dynamic>{},
      },
    );

    return ChatbotResponse.fromJson(
      _apiClient.decode(response) as Map<String, dynamic>,
    );
  }
}
