import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../providers/admin_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_error.dart';

class DemandesScreen extends StatefulWidget {
  const DemandesScreen({super.key});

  @override
  State<DemandesScreen> createState() => _DemandesScreenState();
}

class _DemandesScreenState extends State<DemandesScreen> {
  String _filter = 'all'; // 'all', 'livreur', 'vendeur'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().listenDemandes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();
    final allDemandes = prov.demandes;
    final filtered = allDemandes.where((u) {
      if (_filter == 'livreur') return u.role == UserRole.livreur;
      if (_filter == 'vendeur') return u.role == UserRole.vendeur;
      return true;
    }).toList();

    final nbLivreurs = allDemandes.where((u) => u.role == UserRole.livreur).length;
    final nbRestaurants = allDemandes.where((u) => u.role == UserRole.vendeur).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes d\'adhésion'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('Toutes (${allDemandes.length})'),
                    selected: _filter == 'all',
                    onSelected: (_) => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.two_wheeler, size: 16),
                    label: Text('Livreurs ($nbLivreurs)'),
                    selected: _filter == 'livreur',
                    onSelected: (_) => setState(() => _filter = 'livreur'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.restaurant, size: 16),
                    label: Text('Restaurants ($nbRestaurants)'),
                    selected: _filter == 'vendeur',
                    onSelected: (_) => setState(() => _filter = 'vendeur'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const EmptyView(
              icon: Icons.mark_email_read_outlined,
              message: 'Aucune demande en attente pour le moment.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = filtered[index];
                return _DemandeCard(
                  user: user,
                  onAccepter: () => _confirmerAction(context, user, true),
                  onRefuser: () => _confirmerAction(context, user, false),
                );
              },
            ),
    );
  }

  Future<void> _confirmerAction(BuildContext context, AppUser user, bool accept) async {
    final actionLabel = accept ? 'Accepter' : 'Refuser';
    final roleLabel = user.role == UserRole.livreur ? 'livreur' : 'restaurant partenaire';

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionLabel la demande ?'),
        content: Text(
          accept
              ? 'Confirmez-vous l\'activation du compte $roleLabel pour "${user.nom}" ?\n\nL\'utilisateur pourra dès lors se connecter.'
              : 'Êtes-vous sûr de vouloir refuser la candidature de "${user.nom}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accept ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    final prov = context.read<AdminProvider>();
    if (accept) {
      await prov.accepterDemande(user);
      if (mounted) {
        showSnack(context, 'Candidature acceptée ! Le compte de ${user.nom} est activé.');
      }
    } else {
      await prov.refuserDemande(user);
      if (mounted) {
        showSnack(context, 'Candidature de ${user.nom} refusée.', error: true);
      }
    }
  }
}

class _DemandeCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onAccepter;
  final VoidCallback onRefuser;

  const _DemandeCard({
    required this.user,
    required this.onAccepter,
    required this.onRefuser,
  });

  @override
  Widget build(BuildContext context) {
    final isLivreur = user.role == UserRole.livreur;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLivreur ? Colors.blue.shade50 : Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLivreur ? Colors.blue.shade300 : Colors.deepOrange.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLivreur ? Icons.two_wheeler : Icons.restaurant,
                        size: 16,
                        color: isLivreur ? Colors.blue.shade800 : Colors.deepOrange.shade800,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLivreur ? 'Candidature Livreur' : 'Restaurant Partenaire',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isLivreur ? Colors.blue.shade900 : Colors.deepOrange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(user.dateCreation),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20),
            if (!isLivreur && (user.nomRestaurant?.isNotEmpty ?? false)) ...[
              Text(
                user.nomRestaurant!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Responsable : ${user.nom}',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ] else ...[
              Text(
                user.nom,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text(user.email, style: const TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(user.telephone, style: const TextStyle(fontSize: 13)),
              ],
            ),
            if (isLivreur) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.directions_bike, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Véhicule : ${user.vehicule ?? "Non renseigné"}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
              if (user.zoneLivraison != null && user.zoneLivraison!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Zone : ${user.zoneLivraison}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ],
            if (!isLivreur && user.adresseRestaurant != null && user.adresseRestaurant!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Adresse : ${user.adresseRestaurant}',
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onRefuser,
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  label: const Text('Refuser', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onAccepter,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accepter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
