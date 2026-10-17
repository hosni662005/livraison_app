import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VendeurHome extends StatelessWidget {
  final Widget child;
  const VendeurHome({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    int idx = 0;
    if (loc.contains('/products')) idx = 1;
    else if (loc.contains('/orders')) idx = 2;
    else if (loc.startsWith('/profile')) idx = 3;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/vendeur'); break;
            case 1: context.go('/vendeur/products'); break;
            case 2: context.go('/vendeur/orders'); break;
            case 3: context.go('/profile'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Produits'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Commandes'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
