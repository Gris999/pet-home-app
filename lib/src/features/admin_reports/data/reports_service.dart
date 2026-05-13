import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';

class AdminReportsService {
  AdminReportsService({required this.authService})
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 120),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/pdf, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, */*',
            },
          ),
        );

  final AuthService authService;
  final Dio _dio;

  static const String _n8nBaseUrl =
      'https://petvet.app.n8n.cloud/webhook/chat';

  Future<void> generateReport({
    required String query,
    Map<String, dynamic>? filters,
  }) async {
    final session = await authService.getSession();
    final user = session.user;

    final payload = {
      'action': 'sendMessage',
      'sessionId': 'session${user.idUsuario}49c3832dfefe4505b87442',
      'chatInput': query,
      'email': user.correo,
      'id_veterinaria': session.context.veterinaria?['id_veterinaria'] ?? 1,
    };

    final response = await _dio.post(
      _n8nBaseUrl,
      data: payload,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 600,
      ),
    );

    if (response.statusCode != 200) {
      String msg = 'Error ${response.statusCode} al generar el reporte.';
      try {
        final body = String.fromCharCodes(response.data as List<int>);
        msg += ' Detalle: ${body.substring(0, body.length > 200 ? 200 : body.length)}';
      } catch (_) {}
      throw Exception(msg);
    }

    final bytes = response.data as List<int>;
    final contentType = response.headers.value('content-type') ?? '';

    // Determinar extensión por firma de bytes o Content-Type
    final isPdf = bytes.length > 4 &&
        bytes[0] == 0x25 && bytes[1] == 0x50 &&
        bytes[2] == 0x44 && bytes[3] == 0x46;

    String extension;
    if (isPdf || contentType.contains('pdf')) {
      extension = 'pdf';
    } else if (contentType.contains('excel') ||
        contentType.contains('spreadsheet') ||
        contentType.contains('officedocument.spreadsheetml')) {
      extension = 'xlsx';
    } else if (contentType.contains('csv')) {
      extension = 'csv';
    } else {
      final preview = String.fromCharCodes(bytes.take(100).toList());
      if (contentType.contains('text/html') || preview.trim().startsWith('<')) {
        throw Exception(
          'El servidor respondió con HTML. Verifica la configuración del webhook en n8n.',
        );
      }
      extension = 'pdf'; // Fallback
    }

    // Guardar en carpeta de Descargas pública
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final fileName = 'reporte_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final filePath = '${directory!.path}/$fileName';

    await File(filePath).writeAsBytes(bytes);
    await OpenFile.open(filePath);
  }
}
