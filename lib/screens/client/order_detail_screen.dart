import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/order_timeline.dart';
import '../../widgets/status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail commande')),
      body: StreamBuilder<Order?>(
        stream: OrderRepository().streamById(widget.orderId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) return ErrorView(message: snap.error.toString());
          final o = snap.data;
          if (o == null) return const EmptyView(message: 'Commande introuvable');
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Commande #${o.id.substring(0, 6)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              StatusBadge(status: o.statut),
            ]),
            const SizedBox(height: 4),
            Text(fmtDate(o.dateCreation), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Divider(height: 24),
            const Text('Suivi', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            OrderTimeline(current: o.statut),
            const Divider(height: 24),
            const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold)),
            ...o.items.map((it) => ListTile(
                  dense: true,
                  title: Text(it.nom),
                  subtitle: Text('${fmtPrice(it.prix)} × ${it.quantite}'),
                  trailing: Text(fmtPrice(it.sousTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(fmtPrice(o.total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
            ]),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _info(Icons.location_on_outlined, 'Adresse', o.adresseLivraison),
                  const SizedBox(height: 8),
                  _info(Icons.phone_outlined, 'Téléphone', o.telephone),
                  if (o.note != null) ...[
                    const SizedBox(height: 8),
                    _info(Icons.note_outlined, 'Note', o.note!),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 16),
            // CL-07 : annuler si enAttente
            if (o.canBeCancelled())
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Annuler la commande ?'),
                      content: const Text('Cette action est irréversible.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui, annuler')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await OrderRepository().cancel(o.id);
                    if (context.mounted) showSnack(context, 'Commande annulée');
                  }
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Annuler la commande'),
              ),
          ]);
        },
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) => Row(children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)), Text(value)])),
      ]);
}
