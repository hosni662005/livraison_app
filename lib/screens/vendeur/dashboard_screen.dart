import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _ouvert = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().appUser;
      if (user != null) {
        context.read<ProductProvider>().initForVendeur(user.id);
        context.read<OrderProvider>().listenVendeur(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser;
    final prodProv = context.watch<ProductProvider>();
    final orderProv = context.watch<OrderProvider>();

    if (user == null || prodProv.loading || orderProv.loading) {
      return const Scaffold(body: LoadingView());
    }

    final nbProduits = prodProv.filtered.length;
    final enAttente = orderProv.orders.where((o) => o.statut == OrderStatus.enAttente).length;
    final enPrep = orderProv.orders.where((o) => o.statut == OrderStatus.confirmee || o.statut == OrderStatus.enPreparation).length;

    final now = DateTime.now();
    final caJour = orderProv.orders
        .where((o) =>
            o.dateCreation.year == now.year &&
            o.dateCreation.month == now.month &&
            o.dateCreation.day == now.day &&
            o.statut != OrderStatus.annulee)
        .fold(0.0, (s, o) => s + o.total);

    final caTotal = orderProv.orders
        .where((o) => o.statut != OrderStatus.annulee)
        .fold(0.0, (s, o) => s + o.total);

    final restaurantNom = user.nomRestaurant?.isNotEmpty == true ? user.nomRestaurant! : user.nom;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── TOP AMBER RESTAURANT HEADER ──
            Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 26),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurantNom,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Responsable : ${user.nom}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Ouvert / Fermé switch
                      InkWell(
                        onTap: () {
                          setState(() => _ouvert = !_ouvert);
                          showSnack(
                            context,
                            _ouvert ? 'Votre restaurant est Ouvert aux commandes' : 'Votre restaurant est Fermé',
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _ouvert ? Colors.greenAccent : Colors.white60,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _ouvert ? Colors.greenAccent : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _ouvert ? 'Ouvert' : 'Fermé',
                                style: TextStyle(
                                  color: _ouvert ? Colors.greenAccent : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tableau de bord Restaurant',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── BODY CONTENT ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alert if pending orders
                  if (enAttente > 0) ...[
                    InkWell(
                      onTap: () => context.go('/vendeur/orders'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_active, color: Colors.orange, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$enAttente nouvelle(s) commande(s) en attente de confirmation !',
                                style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 4 KPIs
                  Row(
                    children: [
                      Expanded(child: _kpiCard('CA Aujourd\'hui', fmtPrice(caJour), Icons.payments_outlined, Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.go('/vendeur/orders'),
                          child: _kpiCard('À préparer', '$enAttente nouvelles / $enPrep en cours', Icons.soup_kitchen, Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => context.go('/vendeur/products'),
                          child: _kpiCard('Plats au menu', '$nbProduits plats', Icons.restaurant_menu, Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _kpiCard('CA Total Cumulé', fmtPrice(caTotal), Icons.trending_up, Colors.teal)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text('Actions rapides', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ajouter plat'),
                          onPressed: () => context.push('/vendeur/products/new'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.receipt_long, size: 18),
                          label: const Text('Cuisine & Commandes'),
                          onPressed: () => context.go('/vendeur/orders'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Orders
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Commandes récentes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton(
                        onPressed: () => context.go('/vendeur/orders'),
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (orderProv.orders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text('Aucune commande enregistrée pour le moment', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...orderProv.orders.take(5).map((o) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => context.push('/vendeur/orders/${o.id}'),
                            title: Text(
                              '#${o.id.substring(0, o.id.length > 6 ? 6 : o.id.length).toUpperCase()} — ${fmtPrice(o.total)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${o.items.length} article(s) · ${fmtDate(o.dateCreation)}', style: const TextStyle(fontSize: 12)),
                            trailing: StatusBadge(status: o.statut, compact: true),
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.shade700, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color.shade900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
