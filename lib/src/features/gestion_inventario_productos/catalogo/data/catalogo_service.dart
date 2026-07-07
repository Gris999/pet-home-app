import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';

import '../models/catalogo_producto.dart';
import '../models/product_recommendation.dart';
import 'catalogo_mock_data.dart';

class CatalogoService {
  CatalogoService({
    required AuthService authService,
    http.Client? client,
  })  : _authService = authService,
        _apiClient = ApiClient(authService: authService, client: client);

  final AuthService _authService;
  final ApiClient _apiClient;

  Future<List<CatalogoProducto>> getProductosCatalogo() async {
    return _fetchProducts(
      '/api/gestion/inventario/catalogo-publico/',
      fallback: catalogoProductosMock,
    );
  }

  Future<List<CatalogoProducto>> getProductosDestacados() {
    return _fetchProducts(
      '/api/gestion/inventario/catalogo-publico/?destacado=true',
      fallback: const [],
    );
  }

  Future<List<CatalogoProducto>> getProductosNovedades() {
    return _fetchProducts(
      '/api/gestion/inventario/catalogo-publico/',
      fallback: const [],
      postFilter: (producto) => producto.esNovedadActiva,
    );
  }

  Future<List<CatalogoProducto>> getProductosPromociones() {
    return _fetchProducts(
      '/api/gestion/inventario/catalogo-publico/?con_descuento=true',
      fallback: const [],
    );
  }

  Future<List<CatalogoProducto>> getFavoritos() async {
    try {
      final data = await _apiClient.getList('/api/gestion/inventario/favoritos/');
      return data
          .map((json) => json['producto'])
          .whereType<Map<String, dynamic>>()
          .map((json) {
            return CatalogoProducto.fromJson(
              json,
              baseUrl: _authService.baseUrl,
            ).copyWith(esFavorito: true);
          })
          .where((producto) => producto.visibleCatalogo && producto.estado)
          .toList();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[CatalogoService] favoritos no disponible: $error');
      }
      rethrow;
    }
  }

  Future<void> addFavorito(int productId) async {
    await _apiClient.send(
      method: 'POST',
      path: '/api/gestion/inventario/favoritos/',
      body: <String, dynamic>{'id_producto': productId},
    );
  }

  Future<void> removeFavorito(int productId) async {
    await _apiClient.send(
      method: 'DELETE',
      path: '/api/gestion/inventario/favoritos/$productId/',
    );
  }

  Future<List<ProductRecommendation>> getRecommendationsForPet(int petId) async {
    final response = await _apiClient.send(
      method: 'GET',
      path: '/api/gestion/inventario/recomendaciones/?mascota_id=$petId',
    );
    final decoded = _apiClient.decode(response);
    final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    final raw = data['recomendaciones'];
    final list = raw is List ? raw : const <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => ProductRecommendation.fromJson(
            json,
            baseUrl: _authService.baseUrl,
          ),
        )
        .where((item) => item.product.visibleCatalogo && item.product.estado)
        .toList();
  }

  Future<List<CatalogoProducto>> _fetchProducts(
    String path, {
    required List<CatalogoProducto> fallback,
    bool Function(CatalogoProducto producto)? postFilter,
  }) async {
    try {
      final data = await _apiClient.getList(path);
      final products = data.map((json) {
        return CatalogoProducto.fromJson(json, baseUrl: _authService.baseUrl);
      }).toList();

      final filtered = products.where((producto) {
        return producto.visibleCatalogo && producto.estado;
      });

      if (postFilter != null) {
        return filtered.where(postFilter).toList();
      }

      return filtered.toList();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[CatalogoService] $path no disponible: $error');
      }

      return fallback;
    }
  }
}
