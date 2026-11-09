import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminHome extends StatefulWidget {
  final Widget child;
  const AdminHome({super.key, required this.child});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().listenDemandes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final adminProv = context.watch<AdminProvider>();
    final pendingCount = adminProv.demandes.length;

    int idx = 0;
    if (loc.contains('/demandes')) {
      idx = 0;
    } else if (loc.contains('/users')) {
      idx = 1;
    } else if (loc.contains('/orders')) {
      idx = 2;
    } else if (loc.contains('/stats')) {
      idx = 3;
    } else if (loc.startsWith('/profile')) {
      idx = 4;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/admin/demandes');
              break;
            case 1:
              context.go('/admin/users');
              break;
            case 2:
              context.go('/admin/orders');
              break;
            case 3:
              context.go('/admin/stats');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: pendingCount > 0
                ? Badge(
                    label: Text('$pendingCount'),
                    child: const Icon(Icons.assignment_ind_outlined),
                  )
                : const Icon(Icons.assignment_ind_outlined),
            selectedIcon: pendingCount > 0
                ? Badge(
                    label: Text('$pendingCount'),
                    child: const Icon(Icons.assignment_ind),
                  )
                : const Icon(Icons.assignment_ind),
            label: 'Demandes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Utilisateurs',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Commandes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
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
