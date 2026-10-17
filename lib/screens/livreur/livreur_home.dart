import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LivreurHome extends StatelessWidget {
  final Widget child;
  const LivreurHome({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    int idx = 0;
    if (loc.contains('/deliveries')) idx = 1;
    else if (loc.startsWith('/profile')) idx = 2;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/livreur/available'); break;
            case 1: context.go('/livreur/deliveries'); break;
            case 2: context.go('/profile'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Disponibles'),
          NavigationDestination(icon: Icon(Icons.delivery_dining_outlined), selectedIcon: Icon(Icons.delivery_dining), label: 'Mes livraisons'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
