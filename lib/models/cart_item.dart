import 'product.dart';

class CartItem {
  final Product product;
  int quantite;

  CartItem({required this.product, this.quantite = 1});

  double get sousTotal => product.prix * quantite;

  void increment() => quantite++;
  void decrement() {
    if (quantite > 1) quantite--;
  }
}
