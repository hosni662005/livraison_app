import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().appUser!.id;
      context.read<OrderProvider>().listenClient(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(message: prov.error!, onRetry: () => context.read<OrderProvider>().listenClient(context.read<AuthProvider>().appUser!.id))
              : prov.orders.isEmpty
                  ? const EmptyView(message: 'Aucune commande', icon: Icons.receipt_long)
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
                            trailing: StatusBadge(status: o.statut),
                            isThreeLine: true,
                            onTap: () => context.push('/client/orders/${o.id}'),
                          ),
                        );
                      },
                    ),
    );
  }
}
