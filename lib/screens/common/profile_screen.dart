import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/user_repository.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
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
  void dispose() { _nom.dispose(); _tel.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      await UserRepository().updateProfile(auth.appUser!.id, nom: _nom.text.trim(), telephone: _tel.text.trim());
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
    if (user == null) return const Scaffold(body: Center(child: Text('Non connecté')));
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil'), actions: [
        IconButton(
          icon: Icon(_editing ? Icons.close : Icons.edit),
          onPressed: () => setState(() => _editing = !_editing),
        )
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        CircleAvatar(radius: 40, child: Text(user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?', style: const TextStyle(fontSize: 32))),
        const SizedBox(height: 12),
        Center(child: Chip(label: Text(user.role.label))),
        if (!user.actif) const Card(color: Color(0xFFFFEBEE), child: ListTile(leading: Icon(Icons.block, color: Colors.red), title: Text('Compte désactivé'))),
        const SizedBox(height: 16),
        if (!_editing) ...[
          ListTile(leading: const Icon(Icons.person_outline), title: Text(user.nom), subtitle: const Text('Nom')),
          ListTile(leading: const Icon(Icons.email_outlined), title: Text(user.email), subtitle: const Text('E-mail')),
          ListTile(leading: const Icon(Icons.phone_outlined), title: Text(user.telephone), subtitle: const Text('Téléphone')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () => context.read<AuthProvider>().logout(), icon: const Icon(Icons.logout), label: const Text('Se déconnecter')),
        ] else ...[
          Form(
            key: _form,
            child: Column(children: [
              TextFormField(controller: _nom, decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()), validator: (v) => Validators.required(v, field: 'Nom')),
              const SizedBox(height: 12),
              TextFormField(controller: _tel, decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()), validator: Validators.phone),
              const SizedBox(height: 16),
              FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Enregistrer')),
            ]),
          ),
        ],
      ]),
    );
  }
}
