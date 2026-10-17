import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/product_card.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});
  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().initStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        actions: [
          Stack(children: [
            IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () => context.go('/client/cart')),
            if (cart.count > 0)
              Positioned(
                right: 6, top: 6,
                child: CircleAvatar(radius: 9, backgroundColor: Colors.red, child: Text('${cart.count}', style: const TextStyle(fontSize: 11, color: Colors.white))),
              ),
          ]),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Rechercher un produit...', prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white,
                ),
                onChanged: (v) => prov.setSearch(v),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _chip(prov, null, 'Tous'),
                  ...Category.values.map((c) => _chip(prov, c.value, c.label)),
                ]),
              ),
            ]),
          ),
        ),
      ),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(message: prov.error!, onRetry: () => prov.initStream())
              : prov.filtered.isEmpty
                  ? const EmptyView(message: 'Aucun produit trouvé', icon: Icons.storefront)
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 12, mainAxisSpacing: 12,
                      ),
                      itemCount: prov.filtered.length,
                      itemBuilder: (_, i) {
                        final p = prov.filtered[i];
                        return ProductCard(
                          product: p,
                          onTap: () => context.push('/client/product/${p.id}'),
                          onAddToCart: () {
                            context.read<CartProvider>().add(p);
                            showSnack(context, '${p.nom} ajouté au panier');
                          },
                        );
                      },
                    ),
    );
  }

  Widget _chip(ProductProvider prov, String? value, String label) {
    final selected = prov.categorieFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => prov.setCategorie(value)),
    );
  }
}
