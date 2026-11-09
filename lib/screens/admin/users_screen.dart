import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../providers/admin_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().listenUsers();
      context.read<AdminProvider>().listenDemandes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        actions: [
          IconButton(
            tooltip: 'Demandes en attente',
            icon: prov.demandes.isNotEmpty
                ? Badge(
                    label: Text('${prov.demandes.length}'),
                    child: const Icon(Icons.assignment_ind_outlined),
                  )
                : const Icon(Icons.assignment_ind_outlined),
            onPressed: () => context.go('/admin/demandes'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip(prov, null, 'Tous'),
                ...UserRole.values.map((r) => _filterChip(prov, r, r.label)),
                if (prov.demandes.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.pending_actions, size: 16, color: Colors.deepOrange),
                    label: Text(
                      'En attente (${prov.demandes.length})',
                      style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => context.go('/admin/demandes'),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(message: prov.error!, onRetry: () => prov.listenUsers(role: prov.roleFilter))
              : Column(
                  children: [
                    if (prov.demandes.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.pending_actions, color: Colors.amber.shade900),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${prov.demandes.length} demande(s) en attente (livreur/restaurant)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () => context.go('/admin/demandes'),
                              child: const Text('Voir'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: prov.users.isEmpty
                          ? const EmptyView(message: 'Aucun utilisateur', icon: Icons.people_outline)
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: prov.users.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final u = prov.users[i];
                                final isPending = u.statutDemande == 'enAttente';

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: isPending
                                        ? BorderSide(color: Colors.orange.shade400, width: 1.5)
                                        : BorderSide.none,
                                  ),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: isPending
                                              ? Colors.orange
                                              : (u.actif
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Colors.grey),
                                          child: Icon(
                                            u.role == UserRole.livreur
                                                ? Icons.two_wheeler
                                                : (u.role == UserRole.vendeur
                                                    ? Icons.restaurant
                                                    : Icons.person),
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                u.nom,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  decoration:
                                                      u.actif || isPending ? null : TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ),
                                            if (isPending)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade100,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'En attente',
                                                  style: TextStyle(
                                                    color: Colors.orange.shade900,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          '${u.email}\n${u.telephone} · ${u.role.label}'
                                          '${u.nomRestaurant != null ? " · ${u.nomRestaurant}" : ""}'
                                          '${u.vehicule != null ? " · ${u.vehicule}" : ""}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        isThreeLine: true,
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (v) async {
                                            if (v == 'toggle_actif') {
                                              await prov.toggleActif(u);
                                              if (context.mounted) {
                                                showSnack(context, u.actif ? 'Compte désactivé' : 'Compte activé');
                                              }
                                            }
                                            if (v.startsWith('role:')) {
                                              final role = UserRole.fromString(v.split(':')[1]);
                                              await prov.changeRole(u, role);
                                              if (context.mounted) showSnack(context, 'Rôle → ${role.label}');
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            PopupMenuItem(
                                                value: 'toggle_actif',
                                                child: Text(u.actif ? 'Désactiver le compte' : 'Activer le compte')),
                                            const PopupMenuDivider(),
                                            ...UserRole.values.map((r) => PopupMenuItem(
                                                  value: 'role:${r.value}',
                                                  child: Row(children: [
                                                    if (u.role == r) const Icon(Icons.check, size: 16),
                                                    if (u.role == r) const SizedBox(width: 6),
                                                    Text('Rôle → ${r.label}'),
                                                  ]),
                                                )),
                                          ],
                                        ),
                                      ),
                                      if (isPending) ...[
                                        const Divider(height: 1),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: const BorderSide(color: Colors.red),
                                                ),
                                                onPressed: () async {
                                                  await prov.refuserDemande(u);
                                                  if (context.mounted) {
                                                    showSnack(context, 'Demande de ${u.nom} refusée.', error: true);
                                                  }
                                                },
                                                icon: const Icon(Icons.close, size: 16),
                                                label: const Text('Refuser'),
                                              ),
                                              const SizedBox(width: 8),
                                              FilledButton.icon(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                                onPressed: () async {
                                                  await prov.accepterDemande(u);
                                                  if (context.mounted) {
                                                    showSnack(context, 'Demande de ${u.nom} acceptée ! Compte activé.');
                                                  }
                                                },
                                                icon: const Icon(Icons.check, size: 16),
                                                label: const Text('Accepter'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _filterChip(AdminProvider prov, UserRole? role, String label) {
    final selected = prov.roleFilter == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => prov.listenUsers(role: role),
      ),
    );
  }
}
