import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/pets/models/pet_reminder.dart';

class PetReminderFormPage extends StatefulWidget {
  const PetReminderFormPage({
    super.key,
    this.initialReminder,
  });

  final PetReminder? initialReminder;

  @override
  State<PetReminderFormPage> createState() => _PetReminderFormPageState();
}

class _PetReminderFormPageState extends State<PetReminderFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _type;
  late DateTime _scheduledDate;
  TimeOfDay? _scheduledTime;
  late bool _notify;
  late int _daysBefore;

  static const _types = <MapEntry<String, String>>[
    MapEntry('VACUNA', 'Vacuna'),
    MapEntry('DESPARASITACION', 'Desparasitacion'),
    MapEntry('MEDICAMENTO', 'Medicamento'),
    MapEntry('CONTROL', 'Control'),
    MapEntry('BANIO', 'Banio'),
    MapEntry('PELUQUERIA', 'Peluqueria'),
    MapEntry('OTRO', 'Otro'),
  ];

  @override
  void initState() {
    super.initState();
    final reminder = widget.initialReminder;
    _titleController = TextEditingController(text: reminder?.title ?? '');
    _descriptionController = TextEditingController(text: reminder?.description ?? '');
    _type = reminder?.type ?? 'CONTROL';
    _scheduledDate = reminder?.scheduledDate ?? DateTime.now();
    _scheduledTime = _parseTimeOfDay(reminder?.scheduledTime);
    _notify = reminder?.notify ?? true;
    _daysBefore = reminder?.daysBefore ?? 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialReminder != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar recordatorio' : 'Nuevo recordatorio'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titulo',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Ingresa un titulo.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: _types
                  .map(
                    (type) => DropdownMenuItem(
                      value: type.key,
                      child: Text(type.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _type = value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripcion opcional',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 14),
            _PickerTile(
              icon: Icons.event_outlined,
              title: 'Fecha programada',
              value: _formatDate(_scheduledDate),
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),
            _PickerTile(
              icon: Icons.schedule_outlined,
              title: 'Hora opcional',
              value: _scheduledTime == null ? 'Sin hora' : _formatTime(_scheduledTime!),
              onTap: _pickTime,
              trailing: _scheduledTime == null
                  ? null
                  : IconButton(
                      tooltip: 'Quitar hora',
                      onPressed: () => setState(() => _scheduledTime = null),
                      icon: const Icon(Icons.close),
                    ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notificar'),
              subtitle: const Text('Avisar antes de la fecha programada'),
              value: _notify,
              onChanged: (value) => setState(() => _notify = value),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              value: _daysBefore,
              decoration: const InputDecoration(
                labelText: 'Dias de anticipacion',
                border: OutlineInputBorder(),
              ),
              items: const [0, 1, 2, 3, 5, 7, 14]
                  .map(
                    (days) => DropdownMenuItem(
                      value: days,
                      child: Text(days == 0 ? 'El mismo dia' : '$days dias antes'),
                    ),
                  )
                  .toList(),
              onChanged: _notify
                  ? (value) {
                      if (value == null) return;
                      setState(() => _daysBefore = value);
                    }
                  : null,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined),
              label: Text(isEditing ? 'Guardar cambios' : 'Crear recordatorio'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected == null) return;
    setState(() => _scheduledDate = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (selected == null) return;
    setState(() => _scheduledTime = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final description = _descriptionController.text.trim();
    Navigator.of(context).pop(
      PetReminderRequest(
        type: _type,
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        scheduledDate: _scheduledDate,
        scheduledTime: _scheduledTime == null ? null : _formatTimeForApi(_scheduledTime!),
        notify: _notify,
        daysBefore: _notify ? _daysBefore : 0,
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF6A11CB)),
        title: Text(title),
        subtitle: Text(value),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}

TimeOfDay? _parseTimeOfDay(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

String _formatTimeForApi(TimeOfDay time) => '${_formatTime(time)}:00';

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
