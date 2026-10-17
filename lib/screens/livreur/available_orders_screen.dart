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
    final uid = context.read<AuthProvider>().appUser!.id;
    try {
      await context.read<OrderProvider>().assignToMe(orderId, uid);
      if (!mounted) return;
      showSnack(context, 'Commande assignée — livrée dans "Mes livraisons"');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Commandes disponibles')),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(message: prov.error!, onRetry: () => prov.listenAvailable())
              : prov.orders.isEmpty
                  ? const EmptyView(message: 'Aucune commande disponible', icon: Icons.local_shipping_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: prov.orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final o = prov.orders[i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text('#${o.id.substring(0, 6)} — ${fmtPrice(o.total)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                StatusBadge(status: o.statut),
                              ]),
                              const SizedBox(height: 4),
                              Text(o.adresseLivraison, style: const TextStyle(fontSize: 13)),
                              Text('${o.items.length} article(s) · ${fmtDate(o.dateCreation)}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                  child: OutlinedButton(
                                      onPressed: () => context.push('/livreur/deliveries/${o.id}'),
                                      child: const Text('Détail')),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => _assign(o.id),
                                    icon: const Icon(Icons.assignment_turned_in, size: 18),
                                    label: const Text("S'assigner"),
                                  ),
                                ),
                              ]),
                            ]),
                          ),
                        );
                      },
                    ),
    );
  }
}
