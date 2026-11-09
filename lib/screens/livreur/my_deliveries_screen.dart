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

class MyDeliveriesScreen extends StatefulWidget {
  const MyDeliveriesScreen({super.key});
  @override
  State<MyDeliveriesScreen> createState() => _MyDeliveriesScreenState();
}

class _MyDeliveriesScreenState extends State<MyDeliveriesScreen> {
  String _filter = 'active'; // 'active', 'livree', 'all'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().appUser;
      if (user != null) {
        context.read<OrderProvider>().listenLivreur(user.id);
      }
    });
  }

  Future<void> _advance(Order o) async {
    try {
      await context.read<OrderProvider>().advanceStatus(o.id, o.statut);
      if (mounted) {
        showSnack(
          context,
          o.statut == OrderStatus.prete
              ? 'Course démarrée ! En route vers le client 🛵'
              : 'Livraison réussie ! Bravo 🎉',
        );
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    final allDeliveries = prov.orders;

    final activeDeliveries = allDeliveries
        .where((o) => o.statut == OrderStatus.prete || o.statut == OrderStatus.enLivraison)
        .toList();
    final completedDeliveries = allDeliveries
        .where((o) => o.statut == OrderStatus.livree)
        .toList();

    final filtered = allDeliveries.where((o) {
      if (_filter == 'active') {
        return o.statut == OrderStatus.prete || o.statut == OrderStatus.enLivraison;
      }
      if (_filter == 'livree') return o.statut == OrderStatus.livree;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Livraisons', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(
                  message: prov.error!,
                  onRetry: () {
                    final uid = context.read<AuthProvider>().appUser?.id;
                    if (uid != null) context.read<OrderProvider>().listenLivreur(uid);
                  },
                )
              : Column(
                  children: [
                    // Summary metrics banner
                    Container(
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF263238), Color(0xFF37474F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _metricItem(
                            icon: Icons.two_wheeler,
                            color: Colors.amber,
                            count: '${activeDeliveries.length}',
                            label: 'En cours',
                          ),
                          Container(width: 1, height: 40, color: Colors.white24),
                          _metricItem(
                            icon: Icons.task_alt,
                            color: Colors.greenAccent,
                            count: '${completedDeliveries.length}',
                            label: 'Livrées',
                          ),
                          Container(width: 1, height: 40, color: Colors.white24),
                          _metricItem(
                            icon: Icons.receipt_long,
                            color: Colors.lightBlueAccent,
                            count: '${allDeliveries.length}',
                            label: 'Total',
                          ),
                        ],
                      ),
                    ),

                    // Filter chips
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text('En cours (${activeDeliveries.length})'),
                            selected: _filter == 'active',
                            onSelected: (_) => setState(() => _filter = 'active'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('Livrées (${completedDeliveries.length})'),
                            selected: _filter == 'livree',
                            onSelected: (_) => setState(() => _filter = 'livree'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('Toutes (${allDeliveries.length})'),
                            selected: _filter == 'all',
                            onSelected: (_) => setState(() => _filter = 'all'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Deliveries list
                    Expanded(
                      child: filtered.isEmpty
                          ? EmptyView(
                              message: _filter == 'active'
                                  ? 'Aucune livraison en cours actuellement.\nConsultez les commandes disponibles !'
                                  : 'Aucune livraison trouvée.',
                              icon: Icons.delivery_dining_outlined,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(14),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final o = filtered[i];
                                final isPrete = o.statut == OrderStatus.prete;
                                final isEnLivraison = o.statut == OrderStatus.enLivraison;

                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: isEnLivraison
                                        ? const BorderSide(color: Colors.blue, width: 2)
                                        : BorderSide(color: Colors.grey.shade200),
                                  ),
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
                                        const SizedBox(height: 10),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.location_on, color: Colors.red, size: 20),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                o.adresseLivraison,
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (o.note != null && o.note!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Note : ${o.note!}',
                                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, size: 16, color: Colors.grey),
                                            const SizedBox(width: 6),
                                            Text(o.telephone, style: const TextStyle(fontSize: 13)),
                                            const Spacer(),
                                            Text(
                                              fmtPrice(o.total),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 20),
                                        // Action buttons: Call, GPS, Advance
                                        Row(
                                          children: [
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              ),
                                              icon: const Icon(Icons.phone, size: 16),
                                              label: const Text('Appeler'),
                                              onPressed: () => launchUrl(Uri.parse('tel:${o.telephone}')),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              ),
                                              icon: const Icon(Icons.map_outlined, size: 16),
                                              label: const Text('GPS'),
                                              onPressed: () {
                                                final encoded = Uri.encodeComponent(o.adresseLivraison);
                                                launchUrl(
                                                  Uri.parse('https://maps.google.com/?q=$encoded'),
                                                  mode: LaunchMode.externalApplication,
                                                );
                                              },
                                            ),
                                            const Spacer(),
                                            if (isPrete)
                                              FilledButton.icon(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: Colors.blue.shade700,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                                icon: const Icon(Icons.two_wheeler, size: 16),
                                                label: const Text('Prendre'),
                                                onPressed: () => _advance(o),
                                              ),
                                            if (isEnLivraison)
                                              FilledButton.icon(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                                icon: const Icon(Icons.check_circle, size: 16),
                                                label: const Text('Livrée'),
                                                onPressed: () => _advance(o),
                                              ),
                                            if (!isPrete && !isEnLivraison)
                                              TextButton(
                                                onPressed: () => context.push('/livreur/deliveries/${o.id}'),
                                                child: const Text('Détails'),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _metricItem({
    required IconData icon,
    required Color color,
    required String count,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
