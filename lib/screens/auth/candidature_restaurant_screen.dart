import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';

class CandidatureRestaurantScreen extends StatefulWidget {
  const CandidatureRestaurantScreen({super.key});

  @override
  State<CandidatureRestaurantScreen> createState() => _CandidatureRestaurantScreenState();
}

class _CandidatureRestaurantScreenState extends State<CandidatureRestaurantScreen> {
  final _form = GlobalKey<FormState>();
  final _nomRestaurant = TextEditingController();
  final _nomResponsable = TextEditingController();
  final _tel = TextEditingController();
  final _adresse = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nomRestaurant.dispose();
    _nomResponsable.dispose();
    _tel.dispose();
    _adresse.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.registerRestaurant(
      nomResponsable: _nomResponsable.text,
      nomRestaurant: _nomRestaurant.text,
      email: _email.text,
      telephone: _tel.text,
      password: _pass.text,
      adresseRestaurant: _adresse.text,
    );
    if (!mounted) return;

    if (ok) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
          title: const Text('Demande de partenariat envoyée !'),
          content: const Text(
            'Votre demande pour enregistrer votre restaurant a bien été transmise.\n\n'
            'Elle sera examinée par l\'administrateur. Vous recevrez l\'accès pour gérer votre menu et vos commandes dès validation.',
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
      showSnack(context, auth.error ?? 'Échec lors de l\'envoi de la demande', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devenir Restaurant Partenaire'),
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
                        Icons.restaurant,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rejoignez notre réseau de restaurants',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Proposez vos plats et gérez vos commandes en ligne. Votre compte vendeur sera activé après vérification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _nomRestaurant,
                    decoration: const InputDecoration(
                      labelText: 'Nom du restaurant / enseigne',
                      prefixIcon: Icon(Icons.storefront_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => Validators.required(v, field: 'Nom du restaurant'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nomResponsable,
                    decoration: const InputDecoration(
                      labelText: 'Nom et prénom du responsable',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => Validators.required(v, field: 'Nom du responsable'),
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
                  TextFormField(
                    controller: _adresse,
                    decoration: const InputDecoration(
                      labelText: 'Adresse complète du restaurant',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                      hintText: 'Rue, Ville, Code Postal...',
                    ),
                    validator: (v) => Validators.required(v, field: 'Adresse'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Adresse e-mail professionnelle',
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
                        : const Text('Soumettre ma demande de partenariat', style: TextStyle(fontSize: 16)),
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
