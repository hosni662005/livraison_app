import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().listenVendeur(context.read<AuthProvider>().appUser!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Commandes reçues')),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(message: prov.error!, onRetry: () => prov.listenVendeur(context.read<AuthProvider>().appUser!.id))
              : prov.orders.isEmpty
                  ? const EmptyView(message: 'Aucune commande reçue', icon: Icons.receipt_long_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: prov.orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final o = prov.orders[i];
                        return Card(
                          child: ListTile(
                            title: Text('${o.items.length} article(s) — ${fmtPrice(o.total)}'),
                            subtitle: Text('${fmtDate(o.dateCreation)}\n${o.adresseLivraison}', maxLines: 2, overflow: TextOverflow.ellipsis),
                            isThreeLine: true,
                            trailing: StatusBadge(status: o.statut),
                            onTap: () => context.push('/vendeur/orders/${o.id}'),
                          ),
                        );
                      },
                    ),
    );
  }
}
