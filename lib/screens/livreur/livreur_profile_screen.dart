import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/user_repository.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class LivreurProfileScreen extends StatefulWidget {
  const LivreurProfileScreen({super.key});

  @override
  State<LivreurProfileScreen> createState() => _LivreurProfileScreenState();
}

class _LivreurProfileScreenState extends State<LivreurProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nom;
  late TextEditingController _tel;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().appUser!;
    _nom = TextEditingController(text: u.nom);
    _tel = TextEditingController(text: u.telephone);
  }

  @override
  void dispose() {
    _nom.dispose();
    _tel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      await UserRepository().updateProfile(
        auth.appUser!.id,
        nom: _nom.text.trim(),
        telephone: _tel.text.trim(),
      );
      await auth.refreshUser();
      if (!mounted) return;
      showSnack(context, 'Profil mis à jour');
      setState(() => _editing = false);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Non connecté')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Livreur', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar & Name Card
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8D5B4C),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8D5B4C).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.two_wheeler, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.nom,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Livreur Partenaire Agréé',
                          style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Form or View
            if (_editing)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nom,
                      decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => Validators.required(v, field: 'Nom'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tel,
                      decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone_outlined)),
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Enregistrer les modifications'),
                    ),
                  ],
                ),
              )
            else ...[
              // Info items
              _infoTile(Icons.email_outlined, 'Adresse e-mail', user.email),
              _infoTile(Icons.phone_outlined, 'Téléphone', user.telephone),
              _infoTile(Icons.two_wheeler, 'Moyen de transport', user.vehicule ?? 'Moto / Scooter'),
              _infoTile(Icons.location_on_outlined, 'Zone de livraison', user.zoneLivraison ?? 'Toute la ville'),
              _infoTile(Icons.calendar_month_outlined, 'Date d\'adhésion', fmtDate(user.dateCreation)),
            ],

            const SizedBox(height: 32),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Se déconnecter'),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text('Voulez-vous vraiment vous déconnecter de votre espace livreur ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Se déconnecter'),
                      ),
                    ],
                  ),
                );
                if (ok == true && mounted) {
                  await context.read<AuthProvider>().logout();
                  if (mounted) context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF8D5B4C)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
