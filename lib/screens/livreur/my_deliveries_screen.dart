import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().appUser!.id;
      context.read<OrderProvider>().listenLivreur(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mes livraisons')),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(message: prov.error!, onRetry: () => prov.listenLivreur(context.read<AuthProvider>().appUser!.id))
              : prov.orders.isEmpty
                  ? const EmptyView(message: 'Aucune livraison assignée', icon: Icons.delivery_dining_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: prov.orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final o = prov.orders[i];
                        return Card(
                          child: ListTile(
                            title: Text('#${o.id.substring(0, 6)} — ${fmtPrice(o.total)}'),
                            subtitle: Text('${o.adresseLivraison}\n${fmtDate(o.dateCreation)}', maxLines: 2, overflow: TextOverflow.ellipsis),
                            isThreeLine: true,
                            trailing: StatusBadge(status: o.statut),
                            onTap: () => context.push('/livreur/deliveries/${o.id}'),
                          ),
                        );
                      },
                    ),
    );
  }
}
