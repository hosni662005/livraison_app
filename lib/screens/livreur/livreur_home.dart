import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class LivreurHome extends StatelessWidget {
  final Widget child;
  const LivreurHome({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final orderProv = context.watch<OrderProvider>();

    final enCoursCount = orderProv.orders
        .where((o) => o.statut == OrderStatus.prete || o.statut == OrderStatus.enLivraison)
        .length;

    int idx = 0;
    if (loc == '/livreur' || loc == '/livreur/dashboard') {
      idx = 0;
    } else if (loc.contains('/available')) {
      idx = 1;
    } else if (loc.contains('/en-cours') || loc.contains('/deliveries')) {
      idx = 2;
    } else if (loc.contains('/history')) {
      idx = 3;
    } else if (loc.contains('/gains')) {
      idx = 4;
    } else if (loc.contains('/profile')) {
      idx = 5;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/livreur');
              break;
            case 1:
              context.go('/livreur/available');
              break;
            case 2:
              context.go('/livreur/en-cours');
              break;
            case 3:
              context.go('/livreur/history');
              break;
            case 4:
              context.go('/livreur/gains');
              break;
            case 5:
              context.go('/livreur/profile');
              break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Accueil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Disponibles',
          ),
          NavigationDestination(
            icon: enCoursCount > 0
                ? Badge(
                    label: Text('$enCoursCount'),
                    backgroundColor: const Color(0xFFD81B60),
                    child: const Icon(Icons.local_shipping_outlined),
                  )
                : const Icon(Icons.local_shipping_outlined),
            selectedIcon: enCoursCount > 0
                ? Badge(
                    label: Text('$enCoursCount'),
                    backgroundColor: const Color(0xFFD81B60),
                    child: const Icon(Icons.local_shipping),
                  )
                : const Icon(Icons.local_shipping),
            label: 'En cours',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history_toggle_off),
            label: 'Historique',
          ),
          const NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Gains',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
