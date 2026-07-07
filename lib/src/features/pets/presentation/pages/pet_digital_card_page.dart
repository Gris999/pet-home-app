import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';
import 'package:pethome_app/src/features/pets/models/pet_digital_card.dart';

class PetDigitalCardPage extends StatefulWidget {
  const PetDigitalCardPage({
    super.key,
    required this.petId,
    required this.petsService,
  });

  final int petId;
  final PetsService petsService;

  @override
  State<PetDigitalCardPage> createState() => _PetDigitalCardPageState();
}

class _PetDigitalCardPageState extends State<PetDigitalCardPage> {
  late Future<PetDigitalCard> _future = widget.petsService.getPetDigitalCard(widget.petId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnet digital'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<PetDigitalCard>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ClientException
                ? snapshot.error.toString()
                : 'No se pudo cargar el carnet digital.';
            return _ErrorState(
              message: message,
              onRetry: () {
                setState(() {
                  _future = widget.petsService.getPetDigitalCard(widget.petId);
                });
              },
            );
          }

          final card = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CredentialHeader(card: card),
              const SizedBox(height: 14),
              _QrSection(card: card),
              const SizedBox(height: 12),
              _InfoSection(
                title: 'Identificacion',
                children: [
                  _InfoRow(label: 'Especie', value: card.pet.species ?? 'No registrada'),
                  _InfoRow(label: 'Raza', value: card.pet.breed ?? 'No registrada'),
                  _InfoRow(label: 'Sexo', value: card.pet.sex ?? 'No registrado'),
                  _InfoRow(label: 'Color', value: card.pet.color ?? 'No registrado'),
                  _InfoRow(label: 'Peso', value: card.pet.weight == null ? 'No registrado' : '${card.pet.weight} kg'),
                ],
              ),
              const SizedBox(height: 12),
              _InfoSection(
                title: 'Salud',
                children: [
                  _InfoRow(label: 'Alergias', value: card.pet.allergies ?? 'Sin registro'),
                  _InfoRow(
                    label: 'Consultas',
                    value: '${card.historySummary.totalConsultations}',
                  ),
                  _InfoRow(
                    label: 'Ultima consulta',
                    value: _formatDateText(card.historySummary.lastConsultation),
                  ),
                  if ((card.historySummary.generalObservations ?? '').isNotEmpty)
                    _InfoRow(
                      label: 'Observaciones',
                      value: card.historySummary.generalObservations!,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _ListSection<DigitalVaccine>(
                title: 'Vacunas aplicadas',
                items: card.vaccines,
                emptyText: 'No hay vacunas registradas.',
                itemBuilder: (vaccine) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(vaccine.name),
                  subtitle: Text(
                    'Aplicada: ${_formatDateText(vaccine.appliedDate)}'
                    '${vaccine.nextDate == null ? '' : ' - Proxima: ${_formatDateText(vaccine.nextDate)}'}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ListSection<DigitalPendingPlan>(
                title: 'Proximos cuidados',
                items: card.pendingPlan,
                emptyText: 'No hay cuidados pendientes.',
                itemBuilder: (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.description),
                  subtitle: Text(
                    '${item.typeDisplay} - ${_formatDateText(item.scheduledDate)}',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CredentialHeader extends StatelessWidget {
  const _CredentialHeader({required this.card});

  final PetDigitalCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF6A11CB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.pet.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            card.veterinary.name,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Text(
            'Duenio: ${card.owner.name}',
            style: const TextStyle(color: Colors.white),
          ),
          if ((card.owner.phone ?? '').isNotEmpty)
            Text(
              'Telefono: ${card.owner.phone}',
              style: const TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

class _QrSection extends StatelessWidget {
  const _QrSection({required this.card});

  final PetDigitalCard card;

  @override
  Widget build(BuildContext context) {
    final target = (card.qrUrl?.isNotEmpty ?? false) ? card.qrUrl! : card.qrPayload;
    final qrImageUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${Uri.encodeComponent(target)}';

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Codigo QR del carnet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Escanea para abrir el carnet en PetHome.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.network(
                    qrImageUrl,
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 180,
                      height: 180,
                      child: Center(child: Text('No se pudo cargar el QR')),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ListSection<T> extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.items,
    required this.emptyText,
    required this.itemBuilder,
  });

  final String title;
  final List<T> items;
  final String emptyText;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return _InfoSection(
      title: title,
      children: items.isEmpty
          ? [Text(emptyText, style: const TextStyle(color: Colors.black54))]
          : items.map(itemBuilder).toList(),
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

String _formatDateText(String? value) {
  if (value == null || value.trim().isEmpty) return 'No registrada';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}
