import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pethome_app/src/features/admin_reports/presentation/controllers/reports_controller.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/admin_reports/data/reports_service.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportsController(
        service: AdminReportsService(authService: authService),
      ),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Reportes Administrativos'),
            const SizedBox(height: 8),
            const Text(
              'Filtra manualmente o usa tu voz para que la IA genere el reporte por ti.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Tarjeta de Filtros Manuales
            _buildFilterCard(context, controller),
            
            const SizedBox(height: 24),

            if (controller.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 40),
            
            // Visualizador de Transcripción
            if (controller.isListening || controller.lastTranscription.isNotEmpty)
              _buildTranscriptionBubble(controller),

            const SizedBox(height: 100), // Espacio para el FAB
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildVoiceButton(controller),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6A11CB),
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, ReportsController controller) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Rango de Fechas
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month, color: Color(0xFF6A11CB)),
              title: const Text('Rango de Fechas', style: TextStyle(fontSize: 14)),
              subtitle: Text(
                controller.dateRange == null 
                  ? 'No seleccionado' 
                  : '${controller.dateRange!.start.toString().split(' ')[0]} - ${controller.dateRange!.end.toString().split(' ')[0]}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(primary: Color(0xFF6A11CB)),
                      ),
                      child: child!,
                    );
                  },
                );
                controller.setDateRange(range);
              },
            ),
            const Divider(),
            
            // Tipo de Servicio (Mock)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Servicio',
                border: InputBorder.none,
                icon: Icon(Icons.medical_services_outlined, color: Color(0xFF6A11CB)),
              ),
              items: ['CLINICA', 'DOMICILIO', 'CIRUGIA', 'PELUQUERIA']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => controller.setService(val),
            ),
            const Divider(),

            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.isLoading ? null : () => controller.generateReport(),
                icon: controller.isLoading 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_for_offline),
                label: const Text('Generar Reporte Manual'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionBubble(ReportsController controller) {
    return Column(
      children: [
        const Icon(Icons.auto_awesome, color: Color(0xFFE17116), size: 30),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Text(
            controller.isListening 
              ? controller.lastTranscription.isEmpty ? 'Escuchando...' : controller.lastTranscription
              : 'Enviando comando: "${controller.lastTranscription}"',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceButton(ReportsController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'IA Voice Report',
          style: TextStyle(
            color: Color(0xFF6A11CB),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          width: 80,
          child: FloatingActionButton(
            heroTag: 'reports_fab', // Tag único para evitar el crash de Heroes
            onPressed: controller.isLoading ? null : () => controller.toggleVoiceRecording(),
            backgroundColor: controller.isListening ? Colors.redAccent : const Color(0xFF6A11CB),
            elevation: 8,
            shape: const CircleBorder(),
            child: Icon(
              controller.isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
