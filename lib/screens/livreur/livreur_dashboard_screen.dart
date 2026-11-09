import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';

class LivreurDashboardScreen extends StatefulWidget {
  const LivreurDashboardScreen({super.key});

  @override
  State<LivreurDashboardScreen> createState() => _LivreurDashboardScreenState();
}

class _LivreurDashboardScreenState extends State<LivreurDashboardScreen> {
  bool _enLigne = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().appUser;
      if (user != null) {
        context.read<OrderProvider>().listenLivreur(user.id);
        context.read<OrderProvider>().listenAvailable();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser;
    final orderProv = context.watch<OrderProvider>();

    if (user == null) {
      return const Scaffold(body: LoadingView());
    }

    final allOrders = orderProv.orders;
    final now = DateTime.now();

    // Active deliveries
    final enCoursList = allOrders
        .where((o) => o.statut == OrderStatus.prete || o.statut == OrderStatus.enLivraison)
        .toList();

    // Delivered today
    final livreesAujourdhui = allOrders.where((o) =>
        o.statut == OrderStatus.livree &&
        o.dateCreation.year == now.year &&
        o.dateCreation.month == now.month &&
        o.dateCreation.day == now.day).toList();

    // Gains today (delivery commission: e.g. fixed 250 DA or 15% of order total, or order total)
    // In delivery apps, driver earns delivery fee ~200-300 DA per order or order total
    final gainsJour = livreesAujourdhui.fold(0.0, (sum, o) => sum + (o.total > 0 ? o.total * 0.2 + 200 : 250));

    // This week stats
    final septJours = now.subtract(const Duration(days: 7));
    final livreesSemaine = allOrders.where((o) =>
        o.statut == OrderStatus.livree && o.dateCreation.isAfter(septJours)).toList();
    final gainsSemaine = livreesSemaine.fold(0.0, (sum, o) => sum + (o.total > 0 ? o.total * 0.2 + 200 : 250));

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── TOP BROWN GRADIENT HEADER ──
            Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8D5B4C), Color(0xFFA06B5B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Driver Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.two_wheeler, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour, ${user.nom}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Livreur · ${user.telephone}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // En ligne pill
                      InkWell(
                        onTap: () {
                          setState(() => _enLigne = !_enLigne);
                          showSnack(
                            context,
                            _enLigne ? 'Vous êtes maintenant En ligne' : 'Vous êtes maintenant Hors ligne',
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _enLigne ? Colors.greenAccent : Colors.grey,
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
                                  color: _enLigne ? Colors.greenAccent : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _enLigne ? 'En ligne' : 'Hors ligne',
                                style: TextStyle(
                                  color: _enLigne ? Colors.greenAccent : Colors.white70,
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
                  const SizedBox(height: 28),
                  const Text(
                    'Tableau de bord',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 26,
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
                  // Demo Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8DC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.science_outlined, color: Color(0xFF8D5B4C), size: 22),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Mode démo : les commandes sont synchronisées en direct avec Firebase.',
                            style: TextStyle(
                              color: Color(0xFF5D3E35),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // "Aujourd'hui" title
                  const Text(
                    'Aujourd\'hui',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2x2 colored cards
                  Row(
                    children: [
                      // Livrées (Green)
                      Expanded(
                        child: _statCard(
                          bg: const Color(0xFFEDF8F2),
                          icon: Icons.check_circle,
                          iconColor: const Color(0xFF2E7D32),
                          count: '${livreesAujourdhui.length}',
                          countColor: const Color(0xFF2E7D32),
                          label: 'Livrées',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Gains (Blue)
                      Expanded(
                        child: _statCard(
                          bg: const Color(0xFFEFF5FF),
                          icon: Icons.payments_outlined,
                          iconColor: const Color(0xFF1976D2),
                          count: fmtPrice(gainsJour),
                          countColor: const Color(0xFF1976D2),
                          label: 'Gains',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // En cours (Pink)
                      Expanded(
                        child: InkWell(
                          onTap: () => context.go('/livreur/en-cours'),
                          borderRadius: BorderRadius.circular(16),
                          child: _statCard(
                            bg: const Color(0xFFFDEEF2),
                            icon: Icons.local_shipping,
                            iconColor: const Color(0xFFD81B60),
                            count: '${enCoursList.length}',
                            countColor: const Color(0xFFD81B60),
                            label: 'En cours',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Disponibles (Yellow/Amber)
                      Expanded(
                        child: InkWell(
                          onTap: () => context.go('/livreur/available'),
                          borderRadius: BorderRadius.circular(16),
                          child: _statCard(
                            bg: const Color(0xFFFFF8E7),
                            icon: Icons.inventory_2_outlined,
                            iconColor: const Color(0xFFF57C00),
                            count: '${allOrders.where((o) => o.statut == OrderStatus.prete && o.livreurId == null).length}',
                            countColor: const Color(0xFFF57C00),
                            label: 'Disponibles',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cette semaine summary card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined, color: Color(0xFF8D5B4C), size: 24),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cette semaine',
                              style: TextStyle(fontSize: 11, color: Color(0xFF8D5B4C)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${livreesSemaine.length} livraisons · ${fmtPrice(gainsSemaine)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5D3E35),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Livraisons en cours section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Livraisons en cours',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      if (enCoursList.isNotEmpty)
                        TextButton(
                          onPressed: () => context.go('/livreur/en-cours'),
                          child: const Text('Voir tout'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (enCoursList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.two_wheeler_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          const Text(
                            'Aucune livraison active pour le moment',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () => context.go('/livreur/available'),
                            child: const Text('Prendre une course'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...enCoursList.map((o) => _deliveryCard(context, o)),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required Color bg,
    required IconData icon,
    required Color iconColor,
    required String count,
    required Color countColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: countColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: countColor.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryCard(BuildContext context, Order o) {
    final isEnLivraison = o.statut == OrderStatus.enLivraison;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => context.push('/livreur/deliveries/${o.id}'),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF673AB7), size: 22),
        ),
        title: Text(
          o.adresseLivraison,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Client: ${o.telephone} · ${fmtPrice(o.total)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isEnLivraison ? const Color(0xFFEDE7F6) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isEnLivraison ? 'Récupérée' : 'Prête',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isEnLivraison ? const Color(0xFF673AB7) : const Color(0xFF2E7D32),
            ),
          ),
        ),
      ),
    );
  }
}
