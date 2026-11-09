import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/product_card.dart';

enum ProductSort { recent, priceAsc, priceDesc, nameAsc }

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});
  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final _searchController = TextEditingController();
  ProductSort _sort = ProductSort.recent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().initStream();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _sortProducts(List<Product> list) {
    final copy = List<Product>.from(list);
    switch (_sort) {
      case ProductSort.priceAsc:
        copy.sort((a, b) => a.prix.compareTo(b.prix));
        break;
      case ProductSort.priceDesc:
        copy.sort((a, b) => b.prix.compareTo(a.prix));
        break;
      case ProductSort.nameAsc:
        copy.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
        break;
      case ProductSort.recent:
        copy.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
        break;
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final sortedList = _sortProducts(prov.filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.delivery_dining, color: Color(0xFFFF5722)),
            SizedBox(width: 8),
            Text('Découvrez notre carte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          PopupMenuButton<ProductSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Trier par',
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: ProductSort.recent, child: Text('Plus récents')),
              PopupMenuItem(value: ProductSort.priceAsc, child: Text('Prix croissant')),
              PopupMenuItem(value: ProductSort.priceDesc, child: Text('Prix décroissant')),
              PopupMenuItem(value: ProductSort.nameAsc, child: Text('Nom (A-Z)')),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.go('/client/cart'),
              ),
              if (cart.count > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5722),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${cart.count}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(105),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un plat, dessert, boisson...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              prov.setSearch('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (v) {
                    setState(() {});
                    prov.setSearch(v);
                  },
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip(prov, null, 'Tous', Icons.all_inclusive),
                      _chip(prov, Category.plats.value, Category.plats.label, Icons.restaurant),
                      _chip(prov, Category.boissons.value, Category.boissons.label, Icons.local_cafe),
                      _chip(prov, Category.desserts.value, Category.desserts.label, Icons.cake),
                      _chip(prov, Category.epicerie.value, Category.epicerie.label, Icons.shopping_basket),
                      _chip(prov, Category.autre.value, Category.autre.label, Icons.more_horiz),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(message: prov.error!, onRetry: () => prov.initStream())
              : sortedList.isEmpty
                  ? const EmptyView(message: 'Aucun produit trouvé', icon: Icons.storefront)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            '${sortedList.length} produit(s) disponible(s)',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: sortedList.length,
                            itemBuilder: (_, i) {
                              final p = sortedList[i];
                              return ProductCard(
                                product: p,
                                onTap: () => context.push('/client/product/${p.id}'),
                                onAddToCart: () {
                                  context.read<CartProvider>().add(p);
                                  showSnack(context, '${p.nom} ajouté au panier !');
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _chip(ProductProvider prov, String? value, String label, IconData icon) {
    final selected = prov.categorieFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 16,
          color: selected ? Colors.white : Theme.of(context).colorScheme.primary,
        ),
        label: Text(label),
        selected: selected,
        selectedColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        checkmarkColor: Colors.white,
        showCheckmark: false,
        onSelected: (_) => prov.setCategorie(value),
      ),
    );
  }
}
