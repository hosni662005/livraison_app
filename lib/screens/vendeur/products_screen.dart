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
  final _searchCtrl = TextEditingController();
  String _filter = 'all'; // 'all', 'dispo', 'indispo'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().appUser;
      if (user != null) {
        context.read<ProductProvider>().initForVendeur(user.id);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final all = prov.filtered;

    final filtered = all.where((p) {
      if (_filter == 'dispo') return p.disponible;
      if (_filter == 'indispo') return !p.disponible;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Menu', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un plat du menu...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text('Tous (${all.length})'),
                      selected: _filter == 'all',
                      onSelected: (_) => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      label: Text('Disponibles (${all.where((p) => p.disponible).length})'),
                      selected: _filter == 'dispo',
                      onSelected: (_) => setState(() => _filter = 'dispo'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.do_not_disturb_on, size: 16, color: Colors.red),
                      label: Text('Épuisés (${all.where((p) => !p.disponible).length})'),
                      selected: _filter == 'indispo',
                      onSelected: (_) => setState(() => _filter = 'indispo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/vendeur/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un plat'),
      ),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(
                  message: prov.error!,
                  onRetry: () {
                    final uid = context.read<AuthProvider>().appUser?.id;
                    if (uid != null) context.read<ProductProvider>().initForVendeur(uid);
                  },
                )
              : filtered.isEmpty
                  ? const EmptyView(message: 'Aucun produit trouvé', icon: Icons.inventory_2_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = filtered[i];

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: p.imageUrl.isNotEmpty
                                      ? Image.network(
                                          p.imageUrl,
                                          width: 65,
                                          height: 65,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 65,
                                            height: 65,
                                            color: Colors.grey.shade100,
                                            child: const Icon(Icons.fastfood, color: Colors.grey),
                                          ),
                                        )
                                      : Container(
                                          width: 65,
                                          height: 65,
                                          color: Colors.grey.shade100,
                                          child: const Icon(Icons.fastfood, color: Colors.grey),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.nom,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${p.categorie.toUpperCase()} · ${fmtPrice(p.prix)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            p.disponible ? 'En stock' : 'Épuisé',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: p.disponible ? Colors.green : Colors.red,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Transform.scale(
                                            scale: 0.7,
                                            child: Switch(
                                              value: p.disponible,
                                              activeColor: Colors.green,
                                              onChanged: (val) async {
                                                await prov.update(p.id, {'disponible': val});
                                                if (mounted) {
                                                  showSnack(
                                                    context,
                                                    val ? '${p.nom} marqué disponible' : '${p.nom} marqué épuisé',
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  tooltip: 'Modifier',
                                  onPressed: () => context.push('/vendeur/products/${p.id}/edit'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  tooltip: 'Supprimer',
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Supprimer ce plat ?'),
                                        content: Text('Êtes-vous sûr de vouloir supprimer définitivement "${p.nom}" ?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Annuler'),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Supprimer'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      await prov.delete(p.id);
                                      if (mounted) showSnack(context, 'Produit supprimé', error: true);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
