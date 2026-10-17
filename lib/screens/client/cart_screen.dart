import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/helpers.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Panier'), actions: [
        if (!cart.isEmpty) IconButton(icon: const Icon(Icons.delete_sweep), onPressed: () => cart.clear(), tooltip: 'Vider'),
      ]),
      body: cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Votre panier est vide', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => context.go('/client'), child: const Text('Parcourir le catalogue')),
                ]),
              ),
            )
          : Column(children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final ci = cart.items[i];
                    return ListTile(
                      leading: ci.product.imageUrl.isNotEmpty
                          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(ci.product.imageUrl, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.fastfood)))
                          : Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.fastfood)),
                      title: Text(ci.product.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(fmtPrice(ci.product.prix)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => cart.decrement(ci.product.id)),
                        Text('${ci.quantite}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => cart.increment(ci.product.id)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => cart.remove(ci.product.id)),
                      ]),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(fmtPrice(cart.total), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: FilledButton.icon(icon: const Icon(Icons.check), label: const Text('Passer commande'), onPressed: () => context.push('/client/checkout'))),
                ]),
              ),
            ]),
    );
  }
}
