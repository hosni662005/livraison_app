import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/order_timeline.dart';
import '../../widgets/status_badge.dart';

class OrderManageScreen extends StatefulWidget {
  final String orderId;
  const OrderManageScreen({super.key, required this.orderId});
  @override
  State<OrderManageScreen> createState() => _OrderManageScreenState();
}

class _OrderManageScreenState extends State<OrderManageScreen> {
  final _repo = OrderRepository();
  bool _actionLoading = false;

  Future<void> _advance(Order o) async {
    final next = o.nextStatus();
    if (next == null) {
      showSnack(context, 'Aucune transition possible', error: true);
      return;
    }
    // RG-04 + RG-06 : seul vendeur fait enAttente→prete, séquentiel
    if (next == OrderStatus.enLivraison || next == OrderStatus.livree) {
      showSnack(context, 'Action réservée au livreur', error: true);
      return;
    }
    setState(() => _actionLoading = true);
    try {
      await _repo.updateStatus(o.id, next);
      if (mounted) showSnack(context, 'Statut → ${next.label}');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _cancel(Order o) async {
    if (!o.canBeCancelled()) {
      showSnack(context, 'Annulation impossible (RG-03 : seulement enAttente)', error: true);
      return;
    }
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
    if (ok != true) return;
    setState(() => _actionLoading = true);
    try {
      await _repo.cancel(o.id);
      if (mounted) showSnack(context, 'Commande annulée');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gérer commande')),
      body: StreamBuilder<Order?>(
        stream: _repo.streamById(widget.orderId),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) return ErrorView(message: snap.error.toString());
          final o = snap.data;
          if (o == null) return const EmptyView(message: 'Commande introuvable');

          final canAdvance = o.nextStatus() != null &&
              o.nextStatus() != OrderStatus.enLivraison &&
              o.nextStatus() != OrderStatus.livree &&
              !o.statut.isTerminal;

          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('#${o.id.substring(0, 6)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              Text(fmtPrice(o.total),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
            ]),
            const SizedBox(height: 12),
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
            const SizedBox(height: 20),

            // VE-06 : faire évoluer le statut
            if (canAdvance)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _actionLoading ? null : () => _advance(o),
                  icon: _actionLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.arrow_forward),
                  label: Text('Passer à : ${o.nextStatus()!.label}'),
                ),
              ),

            // VE-07 : annuler si enAttente
            if (o.canBeCancelled()) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: _actionLoading ? null : () => _cancel(o),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler la commande'),
                ),
              ),
            ],

            if (o.statut.isTerminal)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Commande terminée — aucune action possible', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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
