import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/helpers.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  const ProductCard({super.key, required this.product, this.onTap, this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: product.imageUrl.isNotEmpty
                  ? Image.network(product.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 48))
                  : Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 48)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(fmtPrice(product.prix),
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                if (!product.disponible)
                  const Text('Indisponible', style: TextStyle(color: Colors.red, fontSize: 12)),
              ]),
            ),
            if (onAddToCart != null && product.disponible)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: FilledButton.icon(
                  onPressed: onAddToCart,
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('Ajouter'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
