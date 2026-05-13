import 'package:http/http.dart' as http;
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/tracking/models/tracking_models.dart';

class TrackingService {
  TrackingService({
    required AuthService authService,
    http.Client? client,
  }) : _apiClient = ApiClient(authService: authService, client: client);

  final ApiClient _apiClient;

  Future<List<SeguimientoItem>> getSeguimientos({
    SeguimientoFilters filters = const SeguimientoFilters(),
  }) async {
    final path = _withQuery(
      '/api/gestion/notificaciones/seguimientos/',
      filters.toQueryParams(),
    );
    final response = await _apiClient.send(method: 'GET', path: path);
    final decoded = _apiClient.decode(response);
    final rows = _asListOfMap(decoded);
    return rows.map(SeguimientoItem.fromJson).toList(growable: false);
  }

  Future<SeguimientoItem> getSeguimientoDetail(int idSeguimiento) async {
    final response = await _apiClient.send(
      method: 'GET',
      path: '/api/gestion/notificaciones/seguimientos/$idSeguimiento/',
    );
    final decoded = _apiClient.decode(response);
    final row = _asMap(decoded);
    return SeguimientoItem.fromJson(row);
  }

  Future<List<PedidoListItem>> getPedidos({
    PedidoFilters filters = const PedidoFilters(),
  }) async {
    final path = _withQuery(
      '/api/gestion/notificaciones/pedidos/',
      filters.toQueryParams(),
    );
    final response = await _apiClient.send(method: 'GET', path: path);
    final decoded = _apiClient.decode(response);
    final rows = _asListOfMap(decoded);
    return rows.map(PedidoListItem.fromJson).toList(growable: false);
  }

  Future<PedidoDetail> getPedidoDetail(int idPedido) async {
    final response = await _apiClient.send(
      method: 'GET',
      path: '/api/gestion/notificaciones/pedidos/$idPedido/',
    );
    final decoded = _apiClient.decode(response);
    final row = _asMap(decoded);
    return PedidoDetail.fromJson(row);
  }

  String _withQuery(String path, Map<String, String> queryParams) {
    if (queryParams.isEmpty) return path;
    final query = Uri(queryParameters: queryParams).query;
    return '$path?$query';
  }

  Map<String, dynamic> _asMap(Object value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asListOfMap(Object value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    if (value is Map<String, dynamic> && value['results'] is List) {
      final results = value['results'] as List;
      return results.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return <Map<String, dynamic>>[];
  }
}

class SeguimientoFilters {
  const SeguimientoFilters({
    this.tipoSeguimiento,
    this.estadoActual,
    this.visibleCliente,
    this.pedidoId,
    this.citaId,
    this.fechaDesde,
    this.fechaHasta,
  });

  final String? tipoSeguimiento;
  final String? estadoActual;
  final bool? visibleCliente;
  final int? pedidoId;
  final int? citaId;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  Map<String, String> toQueryParams() {
    return <String, String>{
      if (_clean(tipoSeguimiento) != null)
        'tipo_seguimiento': _clean(tipoSeguimiento)!,
      if (_clean(estadoActual) != null) 'estado_actual': _clean(estadoActual)!,
      if (visibleCliente != null)
        'visible_cliente': visibleCliente! ? 'true' : 'false',
      if (pedidoId != null) 'pedido_id': pedidoId.toString(),
      if (citaId != null) 'cita_id': citaId.toString(),
      if (fechaDesde != null) 'fecha_desde': _fmtDate(fechaDesde!),
      if (fechaHasta != null) 'fecha_hasta': _fmtDate(fechaHasta!),
    };
  }
}

class PedidoFilters {
  const PedidoFilters({
    this.estadoPedido,
    this.tipoEntrega,
    this.fechaDesde,
    this.fechaHasta,
  });

  final String? estadoPedido;
  final String? tipoEntrega;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  Map<String, String> toQueryParams() {
    return <String, String>{
      if (_clean(estadoPedido) != null) 'estado_pedido': _clean(estadoPedido)!,
      if (_clean(tipoEntrega) != null) 'tipo_entrega': _clean(tipoEntrega)!,
      if (fechaDesde != null) 'fecha_desde': _fmtDate(fechaDesde!),
      if (fechaHasta != null) 'fecha_hasta': _fmtDate(fechaHasta!),
    };
  }
}

String? _clean(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

String _fmtDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
