import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/status_badge.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({super.key});
  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  OrderStatus? _filter;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().listenAll());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    final filtered = _filter == null ? prov.orders : prov.orders.where((o) => o.statut == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toutes les commandes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(children: [
              ChoiceChip(label: const Text('Toutes'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
              const SizedBox(width: 8),
              ...OrderStatus.values.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(s.label), selected: _filter == s, onSelected: (_) => setState(() => _filter = s)),
              )),
            ]),
          ),
        ),
      ),
      body: prov.loading ? const LoadingView()
          : prov.error != null ? ErrorView(message: prov.error!, onRetry: () => prov.listenAll())
          : filtered.isEmpty ? const EmptyView(message: 'Aucune commande', icon: Icons.receipt_long_outlined)
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              separatorBuilder: (_,__) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final o = filtered[i];
                return Card(child: ListTile(
                  title: Text('#${o.id.substring(0,6)} — ${fmtPrice(o.total)}'),
                  subtitle: Text('${o.items.length} art. · ${fmtDate(o.dateCreation)}\n${o.adresseLivraison}', maxLines: 2, overflow: TextOverflow.ellipsis),
                  isThreeLine: true,
                  trailing: StatusBadge(status: o.statut),
                  onTap: () => context.push('/admin/orders/${o.id}'),
                ));
              },
            ),
    );
  }
}
