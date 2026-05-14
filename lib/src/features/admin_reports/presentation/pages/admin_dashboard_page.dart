import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/auth/domain/auth_user.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.user,
    required this.authService,
    this.onNavigateToReports,
  });

  final AuthUser user;
  final AuthService authService;
  final VoidCallback? onNavigateToReports;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      body: RefreshIndicator(
        onRefresh: () async {
          // Aquí se refrescarían los datos del dashboard
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 24),
              _sectionTitle('Indicadores de Hoy'),
              const SizedBox(height: 16),

              // Fila de KPIs principales
              Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      'Citas hoy',
                      '12',
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _kpiCard(
                      'Ingresos',
                      '\$1,240',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      'Pendientes',
                      '5',
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _kpiCard(
                      'Nuevos Clientes',
                      '3',
                      Icons.person_add,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _sectionTitle('Servicios más solicitados'),
              const SizedBox(height: 16),
              _servicesChart(),

              const SizedBox(height: 32),
              _sectionTitle('Accesos Rápidos'),
              const SizedBox(height: 16),
              _quickAction(
                'Generar Reporte Detallado',
                'Accede a los filtros avanzados y reportes por voz.',
                Icons.analytics_outlined,
                () {
                  if (widget.onNavigateToReports != null) {
                    widget.onNavigateToReports!();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenido, ${widget.user.nombre ?? "Admin"}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Aquí tienes el rendimiento de tu veterinaria hoy.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6A11CB),
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicesChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _chartRow('Consulta General', 0.8, Colors.blue),
          _chartRow('Vacunación', 0.6, Colors.green),
          _chartRow('Cirugía', 0.3, Colors.red),
          _chartRow('Peluquería', 0.5, Colors.orange),
        ],
      ),
    );
  }

  Widget _chartRow(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(percent * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    String title,
    String desc,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF6A11CB).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6A11CB).withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6A11CB), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6A11CB)),
          ],
        ),
      ),
    );
  }
}
