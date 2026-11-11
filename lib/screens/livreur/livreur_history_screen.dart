import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';
import '../../widgets/status_badge.dart';

class LivreurHistoryScreen extends StatefulWidget {
  const LivreurHistoryScreen({super.key});

  @override
  State<LivreurHistoryScreen> createState() => _LivreurHistoryScreenState();
}

class _LivreurHistoryScreenState extends State<LivreurHistoryScreen> {
  String _periode = 'all'; // 'all', 'today', 'week', 'month'
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    final now = DateTime.now();

    // Only past / completed orders
    final pastOrders = prov.orders
        .where((o) => o.statut == OrderStatus.livree || o.statut == OrderStatus.annulee)
        .toList();

    final filtered = pastOrders.where((o) {
      if (_periode == 'today') {
        final sameDay = o.dateCreation.year == now.year &&
            o.dateCreation.month == now.month &&
            o.dateCreation.day == now.day;
        if (!sameDay) return false;
      } else if (_periode == 'week') {
        if (o.dateCreation.isBefore(now.subtract(const Duration(days: 7)))) return false;
      } else if (_periode == 'month') {
        if (o.dateCreation.isBefore(now.subtract(const Duration(days: 30)))) return false;
      }

      final q = _searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final matchAddr = o.adresseLivraison.toLowerCase().contains(q);
        final matchId = o.id.toLowerCase().contains(q);
        final matchTel = o.telephone.contains(q);
        if (!matchAddr && !matchId && !matchTel) return false;
      }
      return true;
    }).toList();

    final totalGains = filtered
        .where((o) => o.statut == OrderStatus.livree)
        .fold(0.0, (s, o) => s + (o.total > 0 ? o.total * 0.2 + 200 : 250));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des courses', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(105),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par adresse ou #ID...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text('Toutes (${pastOrders.length})'),
                      selected: _periode == 'all',
                      onSelected: (_) => setState(() => _periode = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Aujourd\'hui'),
                      selected: _periode == 'today',
                      onSelected: (_) => setState(() => _periode = 'today'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Cette semaine'),
                      selected: _periode == 'week',
                      onSelected: (_) => setState(() => _periode = 'week'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Ce mois'),
                      selected: _periode == 'month',
                      onSelected: (_) => setState(() => _periode = 'month'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(
                  message: prov.error!,
                  onRetry: () {
                    final uid = context.read<AuthProvider>().appUser?.id;
                    if (uid != null) context.read<OrderProvider>().listenLivreur(uid);
                  },
                )
              : Column(
                  children: [
                    // Summary stripe
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Colors.grey.shade100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filtered.length} course(s) trouvée(s)',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Total gains : ${fmtPrice(totalGains)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const EmptyView(
                              message: 'Aucune course terminée dans cette période.',
                              icon: Icons.history,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(14),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final o = filtered[i];
                                final isLivree = o.statut == OrderStatus.livree;
                                final gainsCourse = o.total > 0 ? o.total * 0.2 + 200 : 250.0;

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => context.push('/livreur/deliveries/${o.id}'),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '#${o.id.substring(0, o.id.length > 6 ? 6 : o.id.length).toUpperCase()}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              StatusBadge(status: o.statut),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  o.adresseLivraison,
                                                  style: const TextStyle(fontSize: 13),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${o.items.length} article(s) · Livrée le ${fmtDate(o.dateMiseAJour)}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          ),
                                          const Divider(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Montant commande: ${fmtPrice(o.total)}',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                              Text(
                                                isLivree ? '+ ${fmtPrice(gainsCourse)}' : '0 DA',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: isLivree ? Colors.green.shade700 : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
