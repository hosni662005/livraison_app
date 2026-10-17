import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../repositories/product_repository.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ProductRepository().getById(widget.productId);
      if (mounted) setState(() { _product = p; _loading = false; if (p == null) _error = 'Produit introuvable'; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const LoadingView());
    if (_error != null) return Scaffold(appBar: AppBar(), body: ErrorView(message: _error!, onRetry: _load));
    final p = _product!;
    return Scaffold(
      appBar: AppBar(title: Text(p.nom)),
      body: ListView(children: [
        if (p.imageUrl.isNotEmpty)
          Image.network(p.imageUrl, height: 260, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 48)))
        else
          Container(height: 200, color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 64)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nom, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Chip(label: Text(p.categorie)),
            const SizedBox(height: 8),
            Text(fmtPrice(p.prix), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8),
            if (!p.disponible) const Chip(label: Text('Indisponible'), backgroundColor: Color(0xFFFFEBEE)),
            const SizedBox(height: 16),
            Text(p.description, style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: p.disponible ? () {
                  context.read<CartProvider>().add(p);
                  showSnack(context, '${p.nom} ajouté au panier');
                } : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Ajouter au panier'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
