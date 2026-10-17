import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().initForVendeur(context.read<AuthProvider>().appUser!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mes produits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vendeur/products/new'),
        icon: const Icon(Icons.add), label: const Text('Nouveau'),
      ),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(message: prov.error!, onRetry: () => prov.initForVendeur(context.read<AuthProvider>().appUser!.id))
              : prov.filtered.isEmpty
                  ? const EmptyView(message: 'Aucun produit', icon: Icons.inventory_2_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12,12,12,80),
                      itemCount: prov.filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final p = prov.filtered[i];
                        return Card(
                          child: ListTile(
                            leading: p.imageUrl.isNotEmpty
                                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(p.imageUrl, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)))
                                : Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.fastfood)),
                            title: Text(p.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${fmtPrice(p.prix)} · ${p.categorie} · ${p.disponible ? "Disponible" : "Indispo"}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') context.push('/vendeur/products/${p.id}/edit');
                                if (v == 'delete') {
                                  final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                                    title: const Text('Supprimer ?'),
                                    content: Text('Supprimer "${p.nom}" ?'),
                                    actions: [TextButton(onPressed: ()=> Navigator.pop(context,false), child: const Text('Annuler')), FilledButton(onPressed: ()=> Navigator.pop(context,true), child: const Text('Supprimer'))],
                                  ));
                                  if (ok == true) {
                                    await prov.delete(p.id);
                                    if (context.mounted) showSnack(context, 'Produit supprimé');
                                  }
                                }
                              },
                              itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Modifier')), PopupMenuItem(value: 'delete', child: Text('Supprimer'))],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
