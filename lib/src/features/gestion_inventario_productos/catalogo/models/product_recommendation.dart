import 'catalogo_producto.dart';

class ProductRecommendation {
  const ProductRecommendation({
    required this.product,
    required this.reason,
    this.warning,
  });

  final CatalogoProducto product;
  final String reason;
  final String? warning;

  factory ProductRecommendation.fromJson(
    Map<String, dynamic> json, {
    required String baseUrl,
  }) {
    final productJson = json['producto'];
    return ProductRecommendation(
      product: CatalogoProducto.fromJson(
        productJson is Map<String, dynamic> ? productJson : <String, dynamic>{},
        baseUrl: baseUrl,
      ),
      reason: (json['motivo'] ?? 'Producto recomendado.').toString(),
      warning: _nullableString(json['advertencia']),
    );
  }
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}
