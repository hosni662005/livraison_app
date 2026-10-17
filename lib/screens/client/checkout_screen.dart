import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../repositories/order_repository.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _adresse = TextEditingController();
  final _tel = TextEditingController();
  final _note = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().appUser;
    if (u != null) _tel.text = u.telephone;
  }

  @override
  void dispose() {
    _adresse.dispose();
    _tel.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      showSnack(context, 'Panier vide', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      // CL-04 : grouper vendeurId depuis le premier produit (hypothèse 1 vendeur par commande)
      final items = cart.items
          .map((ci) => OrderItem(
                productId: ci.product.id,
                nom: ci.product.nom,
                prix: ci.product.prix,
                quantite: ci.quantite,
                sousTotal: ci.sousTotal,
              ))
          .toList();
      final order = Order(
        id: '',
        clientId: auth.appUser!.id,
        vendeurId: cart.items.first.product.vendeurId,
        livreurId: null,
        items: items,
        total: cart.total,
        statut: OrderStatus.enAttente,
        adresseLivraison: _adresse.text.trim(),
        telephone: _tel.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        dateCreation: DateTime.now(),
        dateMiseAJour: DateTime.now(),
      );
      await OrderRepository().create(order);
      cart.clear();
      if (!mounted) return;
      showSnack(context, 'Commande passée avec succès !');
      context.go('/client/orders');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Passer commande')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Récapitulatif', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                ...cart.items.map((ci) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text('${ci.product.nom} × ${ci.quantite}')),
                        Text(fmtPrice(ci.sousTotal)),
                      ]),
                    )),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(fmtPrice(cart.total),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                ]),
                const SizedBox(height: 8),
                const Text('Paiement à la livraison (RG-07)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adresse,
            decoration: const InputDecoration(labelText: 'Adresse de livraison *', prefixIcon: Icon(Icons.location_on_outlined), border: OutlineInputBorder()),
            validator: (v) => Validators.required(v, field: 'Adresse'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tel,
            decoration: const InputDecoration(labelText: 'Téléphone *', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Note (optionnel)', prefixIcon: Icon(Icons.note_outlined), border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirmer la commande'),
          ),
        ]),
      ),
    );
  }
}
