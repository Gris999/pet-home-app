import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';
import 'package:pethome_app/src/features/pets/models/pet_image_analysis.dart';

class PetImageAnalysisPage extends StatefulWidget {
  const PetImageAnalysisPage({
    super.key,
    required this.pet,
    required this.petsService,
    this.onScheduleAppointment,
  });

  final Pet pet;
  final PetsService petsService;
  final VoidCallback? onScheduleAppointment;

  @override
  State<PetImageAnalysisPage> createState() => _PetImageAnalysisPageState();
}

class _PetImageAnalysisPageState extends State<PetImageAnalysisPage> {
  final _imagePicker = ImagePicker();

  XFile? _selectedImage;
  PetImageAnalysis? _result;
  late Future<List<PetImageAnalysis>> _historyFuture = _loadHistory();
  bool _isAnalyzing = false;
  String? _message;

  Future<List<PetImageAnalysis>> _loadHistory() {
    return widget.petsService.getPetImageAnalyses(widget.pet.id);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image == null || !mounted) return;
      setState(() {
        _selectedImage = image;
        _message = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'No se pudo seleccionar la imagen.');
      if (kDebugMode) debugPrint('pet_image_pick_error=$error');
    }
  }

  Future<void> _showImageOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _analyze() async {
    final image = _selectedImage;
    if (image == null) {
      setState(() => _message = 'Selecciona o toma una imagen para analizar.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _message = null;
    });

    try {
      final result = await widget.petsService.analyzePetImage(
        petId: widget.pet.id,
        filePath: image.path,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _historyFuture = _loadHistory();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analisis generado correctamente.')),
      );
    } on ClientException catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _message = 'No se pudo analizar la imagen. Intenta nuevamente.',
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _openHistoryResult(PetImageAnalysis item) {
    setState(() => _result = item);
  }

  Color _levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'BAJO':
        return const Color(0xFF10B981);
      case 'MEDIO':
        return const Color(0xFFF59E0B);
      case 'ALTO':
        return const Color(0xFFEF4444);
      case 'URGENTE':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha no registrada';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      appBar: AppBar(
        title: const Text('Analisis preventivo IA'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(pet: widget.pet),
          const SizedBox(height: 12),
          _ImagePickerCard(
            selectedImage: _selectedImage,
            isAnalyzing: _isAnalyzing,
            onPick: _showImageOptions,
            onAnalyze: _analyze,
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _MessageBox(message: _message!),
          ],
          if (_isAnalyzing) ...[
            const SizedBox(height: 12),
            const _LoadingCard(),
          ],
          if (_result != null) ...[
            const SizedBox(height: 12),
            _ResultCard(
              result: _result!,
              levelColor: _levelColor(_result!.attentionLevel),
              onScheduleAppointment: widget.onScheduleAppointment,
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Historial de analisis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<PetImageAnalysis>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return _MessageBox(
                  message: 'No se pudo cargar el historial de analisis.',
                );
              }
              final items = snapshot.data ?? const <PetImageAnalysis>[];
              if (items.isEmpty) {
                return const _EmptyHistory();
              }
              return Column(
                children: items
                    .map(
                      (item) => _HistoryTile(
                        item: item,
                        levelColor: _levelColor(item.attentionLevel),
                        dateLabel: _formatDate(item.createdAt),
                        onTap: () => _openHistoryResult(item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFF59E0B),
              child: Icon(Icons.pets_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${pet.speciesName} - ${pet.breedName ?? 'Raza no registrada'}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.selectedImage,
    required this.isAnalyzing,
    required this.onPick,
    required this.onAnalyze,
  });

  final XFile? selectedImage;
  final bool isAnalyzing;
  final VoidCallback onPick;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Imagen de la mascota',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: selectedImage == null
                  ? Container(
                      height: 180,
                      color: const Color(0xFFF3F4F6),
                      child: const Center(
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          color: Color(0xFF9CA3AF),
                          size: 44,
                        ),
                      ),
                    )
                  : Image.file(
                      File(selectedImage!.path),
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isAnalyzing ? null : onPick,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Elegir foto'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isAnalyzing ? null : onAnalyze,
                    icon: isAnalyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(isAnalyzing ? 'Analizando' : 'Analizar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.levelColor,
    required this.onScheduleAppointment,
  });

  final PetImageAnalysis result;
  final Color levelColor;
  final VoidCallback? onScheduleAppointment;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Resultado preventivo',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    result.attentionLevel,
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ResultSection(
              title: 'Observaciones visibles',
              items: result.visibleObservations,
              emptyText: 'No se identificaron observaciones visibles concretas.',
            ),
            const SizedBox(height: 12),
            _ResultSection(
              title: 'Recomendaciones generales',
              items: result.generalRecommendations,
              emptyText: 'No hay recomendaciones adicionales.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                result.preventiveMessage.isEmpty
                    ? 'Esta orientacion no reemplaza una consulta veterinaria profesional.'
                    : result.preventiveMessage,
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (result.requiresConsultation) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onScheduleAppointment,
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Agendar consulta'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  final String title;
  final List<String> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Text(emptyText, style: const TextStyle(color: Color(0xFF6B7280)))
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.levelColor,
    required this.dateLabel,
    required this.onTap,
  });

  final PetImageAnalysis item;
  final Color levelColor;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: levelColor.withValues(alpha: 0.14),
          child: Icon(Icons.auto_awesome_rounded, color: levelColor),
        ),
        title: Text(
          item.attentionLevel,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(dateLabel),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF6D28D9)),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Analizando imagen. Esto puede tardar unos segundos.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'Aun no hay analisis registrados para esta mascota.',
        style: TextStyle(color: Color(0xFF6B7280)),
      ),
    );
  }
}
