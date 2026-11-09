import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/status_badge.dart';

class OrdersReceivedScreen extends StatefulWidget {
  const OrdersReceivedScreen({super.key});
  @override
  State<OrdersReceivedScreen> createState() => _OrdersReceivedScreenState();
}

class _OrdersReceivedScreenState extends State<OrdersReceivedScreen> {
  String _filter = 'all'; // 'all', 'pending', 'prep', 'ready', 'done'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().appUser;
      if (user != null) {
        context.read<OrderProvider>().listenVendeur(user.id);
      }
    });
  }

  Future<void> _advanceOrder(Order o) async {
    try {
      await context.read<OrderProvider>().advanceStatus(o.id, o.statut);
      if (mounted) showSnack(context, 'Statut de la commande mis à jour');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _cancelOrder(Order o) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser la commande ?'),
        content: Text('Voulez-vous vraiment annuler la commande #${o.id.substring(0, 6)} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Non')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui, refuser'),
          ),
        ],
      ),
    );
    if (conf == true && mounted) {
      try {
        await context.read<OrderProvider>().cancel(o.id);
        if (mounted) showSnack(context, 'Commande annulée', error: true);
      } catch (e) {
        if (mounted) showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    final allOrders = prov.orders;

    final filtered = allOrders.where((o) {
      if (_filter == 'pending') return o.statut == OrderStatus.enAttente;
      if (_filter == 'prep') return o.statut == OrderStatus.confirmee || o.statut == OrderStatus.enPreparation;
      if (_filter == 'ready') return o.statut == OrderStatus.prete;
      if (_filter == 'done') return o.statut == OrderStatus.livree || o.statut == OrderStatus.annulee;
      return true;
    }).toList();

    final nbPending = allOrders.where((o) => o.statut == OrderStatus.enAttente).length;
    final nbPrep = allOrders.where((o) => o.statut == OrderStatus.confirmee || o.statut == OrderStatus.enPreparation).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes du restaurant', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    avatar: const Icon(Icons.notifications_active, size: 16),
                    label: Text('Nouvelles ($nbPending)'),
                    selected: _filter == 'pending',
                    onSelected: (_) => setState(() => _filter = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.soup_kitchen, size: 16),
                    label: Text('En prépa ($nbPrep)'),
                    selected: _filter == 'prep',
                    onSelected: (_) => setState(() => _filter = 'prep'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: Text('Prêtes (${allOrders.where((o) => o.statut == OrderStatus.prete).length})'),
                    selected: _filter == 'ready',
                    onSelected: (_) => setState(() => _filter = 'ready'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Terminées (${allOrders.where((o) => o.statut == OrderStatus.livree || o.statut == OrderStatus.annulee).length})'),
                    selected: _filter == 'done',
                    onSelected: (_) => setState(() => _filter = 'done'),
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
                    if (uid != null) context.read<OrderProvider>().listenVendeur(uid);
                  },
                )
              : filtered.isEmpty
                  ? const EmptyView(message: 'Aucune commande dans cette catégorie', icon: Icons.receipt_long_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final o = filtered[i];

                        return Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: o.statut == OrderStatus.enAttente
                                ? const BorderSide(color: Colors.orange, width: 2)
                                : BorderSide(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/vendeur/orders/${o.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '#${o.id.substring(0, o.id.length > 6 ? 6 : o.id.length).toUpperCase()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      StatusBadge(status: o.statut),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Detail items
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: o.items
                                          .map((it) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Row(
                                                  children: [
                                                    Text('${it.quantite}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(it.nom, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                    Text(fmtPrice(it.sousTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          o.adresseLivraison,
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.phone, size: 18, color: Colors.blue),
                                        tooltip: 'Appeler client',
                                        onPressed: () => launchUrl(Uri.parse('tel:${o.telephone}')),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Total commande', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                          Text(fmtPrice(o.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                      // Action buttons based on status
                                      if (o.statut == OrderStatus.enAttente) ...[
                                        Row(
                                          children: [
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(color: Colors.red),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              ),
                                              onPressed: () => _cancelOrder(o),
                                              child: const Text('Refuser'),
                                            ),
                                            const SizedBox(width: 8),
                                            FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              ),
                                              onPressed: () => _advanceOrder(o),
                                              child: const Text('Accepter'),
                                            ),
                                          ],
                                        ),
                                      ] else if (o.statut == OrderStatus.confirmee) ...[
                                        FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.orange.shade800,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.soup_kitchen, size: 16),
                                          label: const Text('En préparation'),
                                          onPressed: () => _advanceOrder(o),
                                        ),
                                      ] else if (o.statut == OrderStatus.enPreparation) ...[
                                        FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('Commande Prête'),
                                          onPressed: () => _advanceOrder(o),
                                        ),
                                      ] else ...[
                                        OutlinedButton(
                                          onPressed: () => context.push('/vendeur/orders/${o.id}'),
                                          child: const Text('Détails'),
                                        ),
                                      ],
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
