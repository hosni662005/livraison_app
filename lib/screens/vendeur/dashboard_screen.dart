import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().appUser!.id;
      context.read<ProductProvider>().initForVendeur(uid);
      context.read<OrderProvider>().listenVendeur(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prodProv = context.watch<ProductProvider>();
    final orderProv = context.watch<OrderProvider>();

    if (prodProv.loading || orderProv.loading) return const Scaffold(body: LoadingView());

    final nbProduits = prodProv.filtered.length;
    final enAttente = orderProv.orders.where((o) => o.statut == OrderStatus.enAttente).length;
    final now = DateTime.now();
    final caJour = orderProv.orders
        .where((o) => o.dateCreation.year == now.year && o.dateCreation.month == now.month && o.dateCreation.day == now.day && o.statut != OrderStatus.annulee)
        .fold(0.0, (s, o) => s + o.total);

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: _statCard(context, 'CA du jour', fmtPrice(caJour), Icons.payments_outlined, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _statCard(context, 'En attente', '$enAttente', Icons.pending_outlined, Colors.orange)),
        ]),
        const SizedBox(height: 12),
        _statCard(context, 'Produits', '$nbProduits', Icons.inventory_2_outlined, Colors.blue),
        const SizedBox(height: 24),
        const Text('Commandes récentes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (orderProv.orders.isEmpty) const Text('Aucune commande', style: TextStyle(color: Colors.grey)),
        ...orderProv.orders.take(5).map((o) => Card(
              child: ListTile(
                title: Text('${o.items.length} article(s) — ${fmtPrice(o.total)}'),
                subtitle: Text(o.statut.label),
                trailing: Text(fmtDate(o.dateCreation), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            )),
      ]),
    );
  }

  Widget _statCard(BuildContext ctx, String label, String value, IconData icon, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      );
}
