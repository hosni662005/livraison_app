import 'package:flutter/material.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip(prov, null, 'Tous'),
                ...UserRole.values.map((r) => _filterChip(prov, r, r.label)),
              ]),
            ),
          ),
        ),
      ),
      body: prov.loading
          ? const LoadingView()
          : prov.error != null
              ? ErrorView(message: prov.error!, onRetry: () => prov.listenUsers(role: prov.roleFilter))
              : prov.users.isEmpty
                  ? const EmptyView(message: 'Aucun utilisateur', icon: Icons.people_outline)
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: prov.users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final u = prov.users[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: u.actif ? Theme.of(context).colorScheme.primary : Colors.grey,
                              child: Text(u.nom.isNotEmpty ? u.nom[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(u.nom, style: TextStyle(decoration: u.actif ? null : TextDecoration.lineThrough)),
                            subtitle: Text('${u.email}\n${u.telephone} · ${u.role.label}',
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'toggle_actif') {
                                  await prov.toggleActif(u);
                                  if (context.mounted) showSnack(context, u.actif ? 'Compte désactivé' : 'Compte activé');
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
                        );
                      },
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
