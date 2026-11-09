import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/status_badge.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});
  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().listenAvailable();
    });
  }

  Future<void> _assign(String orderId) async {
    final user = context.read<AuthProvider>().appUser;
    if (user == null) return;
    try {
      await context.read<OrderProvider>().assignToMe(orderId, user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Course assignée avec succès !'),
          backgroundColor: Colors.green.shade800,
          action: SnackBarAction(
            label: 'Mes livraisons',
            textColor: Colors.white,
            onPressed: () => context.go('/livreur/deliveries'),
          ),
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses disponibles', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(message: prov.error!, onRetry: () => prov.listenAvailable())
              : prov.orders.isEmpty
                  ? const EmptyView(
                      message: 'Aucune commande prête à livrer pour le moment.\nRevenez d\'ici quelques instants !',
                      icon: Icons.local_shipping_outlined,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Row(
                            children: [
                              const Icon(Icons.flash_on, color: Colors.orange, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '${prov.orders.length} course(s) disponible(s) immédiatement',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(14),
                            itemCount: prov.orders.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final o = prov.orders[i];

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.green.shade200, width: 1.5),
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
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${o.items.length} article(s) à récupérer',
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                          ),
                                          const Spacer(),
                                          Text(
                                            fmtPrice(o.total),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20),
                                      Row(
                                        children: [
                                          OutlinedButton(
                                            onPressed: () => context.push('/livreur/deliveries/${o.id}'),
                                            child: const Text('Détails'),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: FilledButton.icon(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.green.shade700,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              onPressed: () => _assign(o.id),
                                              icon: const Icon(Icons.motorcycle, size: 18),
                                              label: const Text('Prendre cette course', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
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
}
