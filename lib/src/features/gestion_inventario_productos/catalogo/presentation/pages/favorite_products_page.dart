import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/features/compras/presentation/widgets/add_producto_carrito_button.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/data/catalogo_service.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/models/catalogo_producto.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/presentation/pages/product_detail_page.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/widgets/catalogo_widgets.dart';

class FavoriteProductsPage extends StatefulWidget {
  const FavoriteProductsPage({super.key, required this.catalogoService});

  final CatalogoService catalogoService;

  @override
  State<FavoriteProductsPage> createState() => _FavoriteProductsPageState();
}

class _FavoriteProductsPageState extends State<FavoriteProductsPage> {
  late Future<List<CatalogoProducto>> _future =
      widget.catalogoService.getFavoritos();
  final Set<int> _removing = <int>{};

  Future<void> _refresh() async {
    setState(() {
      _future = widget.catalogoService.getFavoritos();
    });
    await _future;
  }

  Future<void> _removeFavorite(CatalogoProducto product) async {
    setState(() => _removing.add(product.idProducto));
    try {
      await widget.catalogoService.removeFavorito(product.idProducto);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto quitado de favoritos.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar favoritos: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _removing.remove(product.idProducto));
      }
    }
  }

  void _openDetail(CatalogoProducto product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: product.copyWith(esFavorito: true),
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
          'Mis favoritos',
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
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: petPurple,
          onRefresh: _refresh,
          child: FutureBuilder<List<CatalogoProducto>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _MessageState(
                  icon: Icons.favorite_border,
                  title: 'No se pudieron cargar tus favoritos',
                  subtitle: snapshot.error.toString(),
                  actionLabel: 'Reintentar',
                  onAction: _refresh,
                );
              }

              final products = snapshot.data ?? const <CatalogoProducto>[];
              if (products.isEmpty) {
                return _MessageState(
                  icon: Icons.favorite_border,
                  title: 'Aun no tienes favoritos',
                  subtitle:
                      'Marca productos con el corazon para encontrarlos rapido aqui.',
                  actionLabel: 'Actualizar',
                  onAction: _refresh,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  final removing = _removing.contains(product.idProducto);
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => _openDetail(product),
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
                                    product.categoria,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                    ),
                                  ),
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
                            IconButton(
                              tooltip: 'Quitar de favoritos',
                              onPressed: removing
                                  ? null
                                  : () => _removeFavorite(product),
                              icon: removing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.favorite,
                                      color: petOrange,
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
