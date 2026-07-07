import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';
import 'package:pethome_app/src/features/pets/models/pet_reminder.dart';
import 'package:pethome_app/src/features/pets/presentation/pages/pet_reminder_form_page.dart';

class PetRemindersPage extends StatefulWidget {
  const PetRemindersPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.petsService,
  });

  final int petId;
  final String petName;
  final PetsService petsService;

  @override
  State<PetRemindersPage> createState() => _PetRemindersPageState();
}

class _PetRemindersPageState extends State<PetRemindersPage> {
  late Future<List<PetReminder>> _future =
      widget.petsService.getPetReminders(widget.petId);
  final Set<int> _busyIds = <int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReminder,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Nuevo'),
      ),
      body: FutureBuilder<List<PetReminder>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ClientException
                ? snapshot.error.toString()
                : 'No se pudieron cargar los recordatorios.';
            return _ErrorState(message: message, onRetry: _reload);
          }

          final items = snapshot.data ?? const <PetReminder>[];
          if (items.isEmpty) {
            return _EmptyState(
              petName: widget.petName,
              onCreate: _createReminder,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final reminder = items[index];
                return _ReminderCard(
                  reminder: reminder,
                  isBusy: _busyIds.contains(reminder.id),
                  onEdit: () => _editReminder(reminder),
                  onComplete: reminder.status == 'PENDIENTE'
                      ? () => _confirmAction(
                            title: 'Completar recordatorio',
                            message: '¿Confirmas que este cuidado ya fue realizado?',
                            actionLabel: 'Completar',
                            action: () => _runAction(
                              reminder.id,
                              () => widget.petsService.completePetReminder(reminder.id),
                              'Recordatorio completado.',
                            ),
                          )
                      : null,
                  onCancel: reminder.status == 'PENDIENTE'
                      ? () => _confirmAction(
                            title: 'Cancelar recordatorio',
                            message: '¿Confirmas que deseas cancelar este recordatorio?',
                            actionLabel: 'Cancelar',
                            action: () => _runAction(
                              reminder.id,
                              () => widget.petsService.cancelPetReminder(reminder.id),
                              'Recordatorio cancelado.',
                            ),
                          )
                      : null,
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
      _future = widget.petsService.getPetReminders(widget.petId);
    });
  }

  Future<void> _createReminder() async {
    final request = await Navigator.of(context).push<PetReminderRequest>(
      MaterialPageRoute(builder: (_) => const PetReminderFormPage()),
    );
    if (request == null) return;
    await _runPageAction(
      () => widget.petsService.createPetReminder(
        petId: widget.petId,
        request: request,
      ),
      'Recordatorio creado.',
    );
  }

  Future<void> _editReminder(PetReminder reminder) async {
    final request = await Navigator.of(context).push<PetReminderRequest>(
      MaterialPageRoute(
        builder: (_) => PetReminderFormPage(initialReminder: reminder),
      ),
    );
    if (request == null) return;
    await _runPageAction(
      () => widget.petsService.updatePetReminder(
        reminderId: reminder.id,
        request: request,
      ),
      'Recordatorio actualizado.',
    );
  }

  Future<void> _runAction(
    int reminderId,
    Future<PetReminder> Function() action,
    String successMessage,
  ) async {
    setState(() => _busyIds.add(reminderId));
    try {
      await action();
      if (!mounted) return;
      _showSnack(successMessage);
      _reload();
    } catch (error) {
      if (!mounted) return;
      _showSnack(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(reminderId));
      }
    }
  }

  Future<void> _runPageAction(
    Future<PetReminder> Function() action,
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

  Future<void> _confirmAction({
    required String title,
    required String message,
    required String actionLabel,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await action();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.isBusy,
    required this.onEdit,
    this.onComplete,
    this.onCancel,
  });

  final PetReminder reminder;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _StatusChip(text: reminder.statusDisplay, status: reminder.status),
                      _OutlineChip(text: reminder.typeDisplay),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'complete') onComplete?.call();
                    if (value == 'cancel') onCancel?.call();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    if (onComplete != null)
                      const PopupMenuItem(value: 'complete', child: Text('Completar')),
                    if (onCancel != null)
                      const PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Fecha: ${_formatDate(reminder.scheduledDate)}'
              '${reminder.scheduledTime == null ? '' : ' - ${_formatApiTime(reminder.scheduledTime!)}'}',
              style: const TextStyle(color: Colors.black87),
            ),
            if ((reminder.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reminder.description!,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  reminder.notify
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  size: 18,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reminder.notify
                        ? 'Aviso ${reminder.daysBefore == 0 ? 'el mismo dia' : '${reminder.daysBefore} dias antes'}'
                        : 'Sin notificacion',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                if (isBusy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.status});

  final String text;
  final String status;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;

    switch (status) {
      case 'COMPLETADO':
        background = const Color(0xFFDCFCE7);
        foreground = const Color(0xFF166534);
        break;
      case 'CANCELADO':
        background = const Color(0xFFE5E7EB);
        foreground = const Color(0xFF374151);
        break;
      case 'VENCIDO':
        background = const Color(0xFFFEE2E2);
        foreground = const Color(0xFFB91C1C);
        break;
      default:
        background = const Color(0xFFFEF3C7);
        foreground = const Color(0xFF92400E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
              'No hay recordatorios para $petName.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('Crear recordatorio'),
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

String _formatApiTime(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return value;
  return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
}
