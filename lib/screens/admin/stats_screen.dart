import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().listenUsers();
      context.read<OrderProvider>().listenAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final orders = context.watch<OrderProvider>();

    if (admin.loading || orders.loading) {
      return const Scaffold(body: LoadingView());
    }
    if (admin.error != null) return Scaffold(body: ErrorView(message: admin.error!));
    if (orders.error != null) return Scaffold(body: ErrorView(message: orders.error!));

    final byRole = admin.countByRole();
    final totalUsers = admin.users.length;
    final totalOrders = orders.orders.length;
    final byStatus = <OrderStatus, int>{};
    double caGlobal = 0;
    for (final o in orders.orders) {
      byStatus[o.statut] = (byStatus[o.statut] ?? 0) + 1;
      if (o.statut != OrderStatus.annulee) caGlobal += o.total;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // AD-05 : CA global + cartes
        Row(children: [
          Expanded(child: _kpi(context, 'CA global', fmtPrice(caGlobal), Icons.payments, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _kpi(context, 'Commandes', '$totalOrders', Icons.receipt_long, Colors.blue)),
        ]),
        const SizedBox(width: 12),
        const SizedBox(height: 12),
        _kpi(context, 'Utilisateurs', '$totalUsers', Icons.people, Colors.deepOrange),

        const SizedBox(height: 24),
        const Text('Utilisateurs par rôle (AD-05)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...byRole.entries.map((e) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${e.value}')),
                title: Text(e.key),
                trailing: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            )),
        if (byRole.isEmpty) const Text('Aucun utilisateur', style: TextStyle(color: Colors.grey)),

        const SizedBox(height: 24),
        const Text('Commandes par statut (AD-05)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...OrderStatus.values.map((s) {
          final n = byStatus[s] ?? 0;
          final pct = totalOrders == 0 ? 0.0 : n / totalOrders;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(s.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  Text('$n', style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: pct, color: s.color, backgroundColor: s.color.withOpacity(0.15)),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _kpi(BuildContext ctx, String label, String value, IconData icon, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      );
}
