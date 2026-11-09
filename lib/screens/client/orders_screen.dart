import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/status_badge.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = 'all'; // 'all', 'active', 'livree', 'annulee'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().appUser;
      if (user != null) {
        context.read<OrderProvider>().listenClient(user.id);
      }
    });
  }

  void _recommander(BuildContext context, Order order) {
    final cart = context.read<CartProvider>();
    for (final item in order.items) {
      final product = Product(
        id: item.productId,
        nom: item.nom,
        description: '',
        prix: item.prix,
        imageUrl: '',
        categorie: 'autre',
        vendeurId: order.vendeurId ?? '',
        disponible: true,
        dateCreation: DateTime.now(),
      );
      cart.addWithQuantity(product, item.quantite);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${order.items.length} article(s) remis dans votre panier !'),
        action: SnackBarAction(
          label: 'Voir panier',
          textColor: Colors.yellow,
          onPressed: () => context.go('/client/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    final allOrders = prov.orders;

    final filtered = allOrders.where((o) {
      if (_filter == 'active') {
        return o.statut != OrderStatus.livree && o.statut != OrderStatus.annulee;
      }
      if (_filter == 'livree') return o.statut == OrderStatus.livree;
      if (_filter == 'annulee') return o.statut == OrderStatus.annulee;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commandes', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('Toutes (${allOrders.length})'),
                    selected: _filter == 'all',
                    onSelected: (_) => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.delivery_dining, size: 16),
                    label: Text(
                      'En cours (${allOrders.where((o) => o.statut != OrderStatus.livree && o.statut != OrderStatus.annulee).length})',
                    ),
                    selected: _filter == 'active',
                    onSelected: (_) => setState(() => _filter = 'active'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(
                      'Livrées (${allOrders.where((o) => o.statut == OrderStatus.livree).length})',
                    ),
                    selected: _filter == 'livree',
                    onSelected: (_) => setState(() => _filter = 'livree'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                      'Annulées (${allOrders.where((o) => o.statut == OrderStatus.annulee).length})',
                    ),
                    selected: _filter == 'annulee',
                    onSelected: (_) => setState(() => _filter = 'annulee'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(
                  message: prov.error!,
                  onRetry: () {
                    final uid = context.read<AuthProvider>().appUser?.id;
                    if (uid != null) context.read<OrderProvider>().listenClient(uid);
                  },
                )
              : filtered.isEmpty
                  ? const EmptyView(message: 'Aucune commande trouvée', icon: Icons.receipt_long)
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final o = filtered[i];
                        final isFinished = o.statut == OrderStatus.livree || o.statut == OrderStatus.annulee;

                        return Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/client/orders/${o.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Commande #${o.id.substring(0, o.id.length > 6 ? 6 : o.id.length).toUpperCase()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      StatusBadge(status: o.statut),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    o.items.map((it) => '${it.quantite}x ${it.nom}').join(', '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fmtDate(o.dateCreation),
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            fmtPrice(o.total),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          if (isFinished)
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                textStyle: const TextStyle(fontSize: 12),
                                              ),
                                              icon: const Icon(Icons.replay, size: 14),
                                              label: const Text('Re-commander'),
                                              onPressed: () => _recommander(context, o),
                                            ),
                                          const SizedBox(width: 8),
                                          FilledButton.tonalIcon(
                                            style: FilledButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              textStyle: const TextStyle(fontSize: 12),
                                            ),
                                            icon: const Icon(Icons.arrow_forward, size: 14),
                                            label: const Text('Suivi'),
                                            onPressed: () => context.push('/client/orders/${o.id}'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
