import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';

class CandidatureLivreurScreen extends StatefulWidget {
  const CandidatureLivreurScreen({super.key});

  @override
  State<CandidatureLivreurScreen> createState() => _CandidatureLivreurScreenState();
}

class _CandidatureLivreurScreenState extends State<CandidatureLivreurScreen> {
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _tel = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _zone = TextEditingController();
  String _vehicule = 'Moto';
  bool _obscure = true;

  final List<String> _vehicules = const [
    'Moto',
    'Scooter',
    'Vélo',
    'Voiture',
    'Trottinette',
  ];

  @override
  void dispose() {
    _nom.dispose();
    _tel.dispose();
    _email.dispose();
    _pass.dispose();
    _zone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.registerLivreur(
      nom: _nom.text,
      email: _email.text,
      telephone: _tel.text,
      password: _pass.text,
      vehicule: _vehicule,
      zoneLivraison: _zone.text.isEmpty ? null : _zone.text,
    );
    if (!mounted) return;

    if (ok) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
          title: const Text('Candidature envoyée !'),
          content: const Text(
            'Votre demande pour devenir livreur a été enregistrée avec succès.\n\n'
            'Elle sera examinée par l\'administrateur. Vous recevrez l\'accès une fois votre profil validé.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/login');
              },
              child: const Text('Retour à la connexion'),
            ),
          ],
        ),
      );
    } else {
      showSnack(context, auth.error ?? 'Échec lors de l\'envoi de la candidature', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devenir Livreur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delivery_dining,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rejoignez notre flotte de livreurs',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Remplissez ce formulaire pour soumettre votre candidature. Un administrateur validera votre compte.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _nom,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => Validators.required(v, field: 'Nom complet'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tel,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _vehicule,
                    decoration: const InputDecoration(
                      labelText: 'Moyen de transport',
                      prefixIcon: Icon(Icons.two_wheeler),
                      border: OutlineInputBorder(),
                    ),
                    items: _vehicules
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _vehicule = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _zone,
                    decoration: const InputDecoration(
                      labelText: 'Ville / Zone de travail souhaitée',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                      hintText: 'Ex: Tunis Centre, Sousse...',
                    ),
                    validator: (v) => Validators.required(v, field: 'Zone de livraison'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Adresse e-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pass,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe (min 6 caractères)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: auth.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Soumettre ma candidature livreur', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Déjà un compte ? Se connecter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
