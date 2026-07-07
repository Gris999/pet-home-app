import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';
import 'package:pethome_app/src/features/pets/models/pet_evolution.dart';
import 'package:pethome_app/src/features/pets/presentation/pages/pet_evolution_form_page.dart';

class PetEvolutionPage extends StatefulWidget {
  const PetEvolutionPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.petsService,
  });

  final int petId;
  final String petName;
  final PetsService petsService;

  @override
  State<PetEvolutionPage> createState() => _PetEvolutionPageState();
}

class _PetEvolutionPageState extends State<PetEvolutionPage> {
  late Future<List<PetEvolutionRecord>> _future =
      widget.petsService.getPetEvolution(widget.petId);
  final Set<int> _busyIds = <int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peso y evolucion'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRecord,
        icon: const Icon(Icons.monitor_weight_outlined),
        label: const Text('Nuevo'),
      ),
      body: FutureBuilder<List<PetEvolutionRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ClientException
                ? snapshot.error.toString()
                : 'No se pudo cargar la evolucion.';
            return _ErrorState(message: message, onRetry: _reload);
          }

          final items = snapshot.data ?? const <PetEvolutionRecord>[];
          if (items.isEmpty) {
            return _EmptyState(petName: widget.petName, onCreate: _createRecord);
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) return _SummaryCard(items: items);
                final record = items[index - 1];
                return _EvolutionCard(
                  record: record,
                  isBusy: _busyIds.contains(record.id),
                  onEdit: () => _editRecord(record),
                  onDelete: () => _deleteRecord(record),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _reload() {
    setState(() {
      _future = widget.petsService.getPetEvolution(widget.petId);
    });
  }

  Future<void> _createRecord() async {
    final request = await Navigator.of(context).push<PetEvolutionRequest>(
      MaterialPageRoute(builder: (_) => const PetEvolutionFormPage()),
    );
    if (request == null) return;
    await _runPageAction(
      () => widget.petsService.createPetEvolution(
        petId: widget.petId,
        request: request,
      ),
      'Registro creado.',
    );
  }

  Future<void> _editRecord(PetEvolutionRecord record) async {
    final request = await Navigator.of(context).push<PetEvolutionRequest>(
      MaterialPageRoute(
        builder: (_) => PetEvolutionFormPage(initialRecord: record),
      ),
    );
    if (request == null) return;
    await _runPageAction(
      () => widget.petsService.updatePetEvolution(
        recordId: record.id,
        request: request,
      ),
      'Registro actualizado.',
    );
  }

  Future<void> _deleteRecord(PetEvolutionRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('Esta accion quitara el registro de evolucion.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyIds.add(record.id));
    try {
      await widget.petsService.deletePetEvolution(record.id);
      if (!mounted) return;
      _showSnack('Registro eliminado.');
      _reload();
    } catch (error) {
      if (!mounted) return;
      _showSnack(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busyIds.remove(record.id));
    }
  }

  Future<void> _runPageAction(
    Future<PetEvolutionRecord> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) return;
      _showSnack(successMessage);
      _reload();
    } catch (error) {
      if (!mounted) return;
      _showSnack(_errorMessage(error));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.items});

  final List<PetEvolutionRecord> items;

  @override
  Widget build(BuildContext context) {
    final latest = items.first;
    final previous = items.length > 1 ? items[1] : null;
    final difference = previous == null ? null : latest.weight - previous.weight;
    final diffText = difference == null
        ? 'Sin comparacion'
        : '${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(2)} kg';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_weight_outlined, color: Color(0xFF1D4ED8), size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${latest.weight.toStringAsFixed(2)} kg',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text('${latest.bodyConditionDisplay} - $diffText'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard({
    required this.record,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final PetEvolutionRecord record;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: ListTile(
        title: Text('${record.weight.toStringAsFixed(2)} kg'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${record.bodyConditionDisplay} - ${_formatDate(record.recordDate)}'),
            if ((record.note ?? '').trim().isNotEmpty) Text(record.note!),
          ],
        ),
        trailing: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.petName, required this.onCreate});

  final String petName;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No hay registros de evolucion para $petName.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.monitor_weight_outlined),
              label: const Text('Registrar peso'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

String _errorMessage(Object error) {
  if (error is ClientException) return error.toString();
  return 'No se pudo completar la accion.';
}

String _formatDate(DateTime? date) {
  if (date == null) return 'No registrada';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
