import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/pets/models/pet_evolution.dart';

class PetEvolutionFormPage extends StatefulWidget {
  const PetEvolutionFormPage({super.key, this.initialRecord});

  final PetEvolutionRecord? initialRecord;

  @override
  State<PetEvolutionFormPage> createState() => _PetEvolutionFormPageState();
}

class _PetEvolutionFormPageState extends State<PetEvolutionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _noteController;
  late String _condition;
  late DateTime _recordDate;

  static const _conditions = <MapEntry<String, String>>[
    MapEntry('BAJO', 'Bajo peso'),
    MapEntry('NORMAL', 'Normal'),
    MapEntry('SOBREPESO', 'Sobrepeso'),
    MapEntry('OBESIDAD', 'Obesidad'),
    MapEntry('NO_EVALUADO', 'No evaluado'),
  ];

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    _weightController = TextEditingController(
      text: record == null ? '' : record.weight.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: record?.note ?? '');
    _condition = record?.bodyCondition ?? 'NO_EVALUADO';
    _recordDate = record?.recordDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialRecord != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar evolucion' : 'Nuevo registro'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Peso en kg',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) return 'Ingresa un peso valido.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _condition,
              decoration: const InputDecoration(
                labelText: 'Condicion corporal',
                border: OutlineInputBorder(),
              ),
              items: _conditions
                  .map((item) => DropdownMenuItem(value: item.key, child: Text(item.value)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _condition = value);
              },
            ),
            const SizedBox(height: 14),
            _DateTile(
              value: _formatDate(_recordDate),
              onTap: _pickDate,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Nota opcional',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined),
              label: Text(isEditing ? 'Guardar cambios' : 'Registrar evolucion'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (selected == null) return;
    setState(() => _recordDate = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final note = _noteController.text.trim();
    Navigator.of(context).pop(
      PetEvolutionRequest(
        weight: double.parse(_weightController.text.trim().replaceAll(',', '.')),
        bodyCondition: _condition,
        recordDate: _recordDate,
        note: note.isEmpty ? null : note,
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.event_outlined, color: Color(0xFF6A11CB)),
        title: const Text('Fecha de registro'),
        subtitle: Text(value),
        trailing: const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
