import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../models/app_user.dart';
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
      context.read<AdminProvider>().listenDemandes();
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
    final pendingDemandes = admin.demandes.length;

    final byStatus = <OrderStatus, int>{};
    double caGlobal = 0;
    int ordersLivrees = 0;

    for (final o in orders.orders) {
      byStatus[o.statut] = (byStatus[o.statut] ?? 0) + 1;
      if (o.statut != OrderStatus.annulee) caGlobal += o.total;
      if (o.statut == OrderStatus.livree) ordersLivrees++;
    }

    final panierMoyen = totalOrders > 0 ? (caGlobal / totalOrders) : 0.0;
    final tauxSucces = totalOrders > 0 ? ((ordersLivrees / totalOrders) * 100).toStringAsFixed(0) : '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytique & Statistiques', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 4 KPIs Grid
          Row(
            children: [
              Expanded(
                child: _kpi(
                  context,
                  'Chiffre d\'affaires',
                  fmtPrice(caGlobal),
                  Icons.payments_outlined,
                  Colors.green.shade700,
                  Colors.green.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpi(
                  context,
                  'Panier moyen',
                  fmtPrice(panierMoyen),
                  Icons.shopping_basket_outlined,
                  Colors.teal.shade700,
                  Colors.teal.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _kpi(
                  context,
                  'Total Commandes',
                  '$totalOrders ($tauxSucces% livrées)',
                  Icons.receipt_long_outlined,
                  Colors.blue.shade700,
                  Colors.blue.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => context.go('/admin/demandes'),
                  borderRadius: BorderRadius.circular(16),
                  child: _kpi(
                    context,
                    'Demandes en attente',
                    '$pendingDemandes',
                    Icons.assignment_ind_outlined,
                    Colors.deepOrange,
                    Colors.deepOrange.shade50,
                    showArrow: true,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text('Répartition des utilisateurs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _roleCard(
                  title: 'Clients',
                  count: byRole[UserRole.client.value] ?? 0,
                  icon: Icons.person_outline,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _roleCard(
                  title: 'Restaurants',
                  count: byRole[UserRole.vendeur.value] ?? 0,
                  icon: Icons.restaurant,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _roleCard(
                  title: 'Livreurs',
                  count: byRole[UserRole.livreur.value] ?? 0,
                  icon: Icons.two_wheeler,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text('État des commandes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...OrderStatus.values.map((s) {
            final n = byStatus[s] ?? 0;
            final pct = totalOrders == 0 ? 0.0 : n / totalOrders;

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(s.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        Text(
                          '$n (${(pct * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        color: s.color,
                        backgroundColor: s.color.withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _kpi(
    BuildContext ctx,
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg, {
    bool showArrow = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (showArrow) Icon(Icons.arrow_forward_ios, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
