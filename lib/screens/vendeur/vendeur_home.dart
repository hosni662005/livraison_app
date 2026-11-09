import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class VendeurHome extends StatelessWidget {
  final Widget child;
  const VendeurHome({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final orderProv = context.watch<OrderProvider>();
    final pendingOrders = orderProv.orders.where((o) => o.statut == OrderStatus.enAttente).length;

    int idx = 0;
    if (loc.contains('/products')) {
      idx = 1;
    } else if (loc.contains('/orders')) {
      idx = 2;
    } else if (loc.startsWith('/profile')) {
      idx = 3;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/vendeur');
              break;
            case 1:
              context.go('/vendeur/products');
              break;
            case 2:
              context.go('/vendeur/orders');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: pendingOrders > 0
                ? Badge(
                    label: Text('$pendingOrders'),
                    child: const Icon(Icons.receipt_long_outlined),
                  )
                : const Icon(Icons.receipt_long_outlined),
            selectedIcon: pendingOrders > 0
                ? Badge(
                    label: Text('$pendingOrders'),
                    child: const Icon(Icons.receipt_long),
                  )
                : const Icon(Icons.receipt_long),
            label: 'Commandes',
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
