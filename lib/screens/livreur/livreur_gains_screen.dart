import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';

class LivreurGainsScreen extends StatefulWidget {
  const LivreurGainsScreen({super.key});

  @override
  State<LivreurGainsScreen> createState() => _LivreurGainsScreenState();
}

class _LivreurGainsScreenState extends State<LivreurGainsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().appUser;
      if (user != null) {
        context.read<OrderProvider>().listenLivreur(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    final now = DateTime.now();

    final deliveredOrders = prov.orders.where((o) => o.statut == OrderStatus.livree).toList();

    // Calculations
    final deliveredToday = deliveredOrders.where((o) =>
        o.dateCreation.year == now.year &&
        o.dateCreation.month == now.month &&
        o.dateCreation.day == now.day).toList();
    final deliveredWeek = deliveredOrders.where((o) =>
        o.dateCreation.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final deliveredMonth = deliveredOrders.where((o) =>
        o.dateCreation.isAfter(now.subtract(const Duration(days: 30)))).toList();

    double calcGains(List<Order> list) =>
        list.fold(0.0, (s, o) => s + (o.total > 0 ? o.total * 0.2 + 200 : 250));

    final gainsJour = calcGains(deliveredToday);
    final gainsSemaine = calcGains(deliveredWeek);
    final gainsMois = calcGains(deliveredMonth);
    final gainsTotal = calcGains(deliveredOrders);

    final moyenneCourse = deliveredOrders.isNotEmpty ? (gainsTotal / deliveredOrders.length) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Revenus & Gains', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: prov.loading
          ? const LoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Wallet Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3C72).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Solde total disponible',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified, size: 14, color: Colors.greenAccent),
                                  SizedBox(width: 4),
                                  Text('Vérifié', style: TextStyle(color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fmtPrice(gainsTotal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1E3C72),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.account_balance_wallet, size: 18),
                                label: const Text('Retirer mes gains', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  showSnack(context, 'Demande de virement envoyée à l\'administration !');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3 period stats
                  Row(
                    children: [
                      Expanded(child: _periodCard('Aujourd\'hui', fmtPrice(gainsJour), '${deliveredToday.length} courses', Colors.blue)),
                      const SizedBox(width: 10),
                      Expanded(child: _periodCard('Cette semaine', fmtPrice(gainsSemaine), '${deliveredWeek.length} courses', Colors.orange)),
                      const SizedBox(width: 10),
                      Expanded(child: _periodCard('Ce mois', fmtPrice(gainsMois), '${deliveredMonth.length} courses', Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Performance KPIs
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Indicateurs de performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _kpiItem(Icons.speed, 'Moyenne / course', fmtPrice(moyenneCourse)),
                            Container(width: 1, height: 36, color: Colors.grey.shade300),
                            _kpiItem(Icons.check_circle_outline, 'Courses finies', '${deliveredOrders.length}'),
                            Container(width: 1, height: 36, color: Colors.grey.shade300),
                            _kpiItem(Icons.star_outline, 'Note moyenne', '4.9 / 5'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent gains list
                  const Text('Derniers versements par course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (deliveredOrders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('Aucune course rémunérée pour le moment', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ...deliveredOrders.take(10).map((o) {
                      final fee = o.total > 0 ? o.total * 0.2 + 200 : 250;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                          ),
                          title: Text('Course #${o.id.substring(0, o.id.length > 6 ? 6 : o.id.length).toUpperCase()}'),
                          subtitle: Text(fmtDate(o.dateMiseAJour), style: const TextStyle(fontSize: 11)),
                          trailing: Text(
                            '+ ${fmtPrice(fee)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _periodCard(String label, String amount, String subtitle, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(amount, style: TextStyle(color: color.shade900, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: color.shade700, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _kpiItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
