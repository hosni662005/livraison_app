import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/order_timeline.dart';
import '../../widgets/status_badge.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final String orderId;
  const DeliveryDetailScreen({super.key, required this.orderId});
  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final _repo = OrderRepository();
  bool _loading = false;

  Future<void> _advance(Order o) async {
    final next = o.nextStatus();
    if (next == null) {
      showSnack(context, 'Aucune transition possible', error: true);
      return;
    }
    // LI-04 : prete → enLivraison → livree
    if (next == OrderStatus.confirmee || next == OrderStatus.enPreparation || next == OrderStatus.prete) {
      showSnack(context, 'Action réservée au vendeur', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.updateStatus(o.id, next);
      if (mounted) showSnack(context, 'Statut → ${next.label}');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMaps(String adresse) async {
    final uri = Uri.parse(mapsUrl(adresse));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) showSnack(context, 'Impossible d\'ouvrir Maps', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail livraison')),
      body: StreamBuilder<Order?>(
        stream: _repo.streamById(widget.orderId),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) return ErrorView(message: snap.error.toString());
          final o = snap.data;
          if (o == null) return const EmptyView(message: 'Commande introuvable');

          final canAdvance = o.nextStatus() != null &&
              (o.statut == OrderStatus.prete || o.statut == OrderStatus.enLivraison) &&
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
              Text(fmtPrice(o.total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
            ]),
            const SizedBox(height: 16),
            // LI-05 : adresse + téléphone + lien Maps
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _info(Icons.location_on_outlined, 'Adresse de livraison', o.adresseLivraison),
                  const SizedBox(height: 8),
                  _info(Icons.phone_outlined, 'Téléphone client', o.telephone),
                  if (o.note != null) ...[
                    const SizedBox(height: 8),
                    _info(Icons.note_outlined, 'Note', o.note!),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openMaps(o.adresseLivraison),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Ouvrir dans Google Maps'),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            if (canAdvance)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : () => _advance(o),
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.delivery_dining),
                  label: Text(o.statut == OrderStatus.prete ? 'Commencer la livraison' : 'Marquer comme livrée'),
                ),
              ),
            if (o.statut.isTerminal)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Livraison terminée', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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
