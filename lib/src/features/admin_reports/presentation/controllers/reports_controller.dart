import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/admin_reports/data/reports_service.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ReportsController extends ChangeNotifier {
  ReportsController({required AdminReportsService service})
    : _service = service;

  final AdminReportsService _service;
  final SpeechToText _speech = SpeechToText();

  bool isLoading = false;
  bool isListening = false;
  String? errorMessage;
  String lastTranscription = '';

  // Filtros manuales
  DateTimeRange? dateRange;
  String? selectedService;
  String? selectedStatus;

  Future<void> toggleVoiceRecording() async {
    if (isLoading) return;

    if (isListening) {
      await stopListeningAndSend();
      return;
    }

    errorMessage = null;
    lastTranscription = '';

    final available = await _speech.initialize(
      onError: (error) {
        isListening = false;
        errorMessage = 'Error de voz: ${error.errorMsg}';
        notifyListeners();
      },
    );

    if (!available) {
      errorMessage = 'No se pudo activar el reconocimiento de voz.';
      notifyListeners();
      return;
    }

    isListening = true;
    notifyListeners();

    await _speech.listen(
      localeId: 'es_ES',
      onResult: (result) {
        lastTranscription = result.recognizedWords;
        if (result.finalResult) {
          stopListeningAndSend();
        }
        notifyListeners();
      },
    );
  }

  Future<void> stopListeningAndSend() async {
    if (!isListening) return;

    isListening = false;
    await _speech.stop();
    notifyListeners();

    if (lastTranscription.trim().isNotEmpty) {
      await generateReport(query: lastTranscription);
    }
  }

  Future<void> generateReport({String? query}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Combinar filtros manuales si existen
      final filters = {
        if (dateRange != null) ...{
          'start_date': dateRange!.start.toIso8601String(),
          'end_date': dateRange!.end.toIso8601String(),
        },
        if (selectedService != null) 'service_type': selectedService,
        if (selectedStatus != null) 'status': selectedStatus,
      };

      await _service.generateReport(
        query: query ?? 'Reporte manual generado desde filtros',
        filters: filters,
      );

      lastTranscription = ''; // Limpiar después de éxito
    } catch (e) {
      errorMessage = 'Error al generar reporte: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setDateRange(DateTimeRange? range) {
    dateRange = range;
    notifyListeners();
  }

  void setService(String? service) {
    selectedService = service;
    notifyListeners();
  }

  void setStatus(String? status) {
    selectedStatus = status;
    notifyListeners();
  }
}
