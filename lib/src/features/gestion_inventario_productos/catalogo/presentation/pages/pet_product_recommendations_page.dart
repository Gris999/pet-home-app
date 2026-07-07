import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/features/compras/presentation/widgets/add_producto_carrito_button.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/data/catalogo_service.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/models/product_recommendation.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/presentation/pages/product_detail_page.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/widgets/catalogo_widgets.dart';

class PetProductRecommendationsPage extends StatefulWidget {
  const PetProductRecommendationsPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.catalogoService,
  });

  final int petId;
  final String petName;
  final CatalogoService catalogoService;

  @override
  State<PetProductRecommendationsPage> createState() =>
      _PetProductRecommendationsPageState();
}

class _PetProductRecommendationsPageState extends State<PetProductRecommendationsPage> {
  late Future<List<ProductRecommendation>> _future =
      widget.catalogoService.getRecommendationsForPet(widget.petId);

  Future<void> _refresh() async {
    setState(() {
      _future = widget.catalogoService.getRecommendationsForPet(widget.petId);
    });
    await _future;
  }

  void _openDetail(ProductRecommendation item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: item.product,
          catalogoService: widget.catalogoService,
          onFavoriteChanged: (_) => _refresh(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: petPurple,
        title: const Text(
          'Productos recomendados',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [petPurpleDark, petPurple, petPurpleSoft],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: petPurple,
        onRefresh: _refresh,
        child: FutureBuilder<List<ProductRecommendation>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.auto_awesome_outlined,
                title: 'No se pudieron cargar recomendaciones',
                subtitle: snapshot.error.toString(),
                actionLabel: 'Reintentar',
                onAction: _refresh,
              );
            }

            final items = snapshot.data ?? const <ProductRecommendation>[];
            if (items.isEmpty) {
              return _MessageState(
                icon: Icons.auto_awesome_outlined,
                title: 'Sin recomendaciones por ahora',
                subtitle: 'Cuando haya productos compatibles con ${widget.petName}, apareceran aqui.',
                actionLabel: 'Actualizar',
                onAction: _refresh,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final product = item.product;
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () => _openDetail(item),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 86,
                            child: ProductImageBox(
                              product: product,
                              height: 86,
                              showBadges: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.nombre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.reason,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                                if ((item.warning ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    item.warning!,
                                    style: const TextStyle(
                                      color: Color(0xFFB45309),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  'Bs ${product.precioVisible.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: petOrange,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                AddProductoCarritoButton(
                                  productoId: product.idProducto,
                                  enabled: product.tieneStock,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 54, color: petPurple),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6B7280), height: 1.35),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}
