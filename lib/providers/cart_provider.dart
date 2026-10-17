import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get count => _items.fold(0, (s, e) => s + e.quantite);
  double get total => _items.fold(0, (s, e) => s + e.sousTotal);
  bool get isEmpty => _items.isEmpty;

  void add(Product product) {
    final idx = _items.indexWhere((e) => e.product.id == product.id);
    if (idx >= 0) {
      _items[idx].increment();
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.removeWhere((e) => e.product.id == productId);
    notifyListeners();
  }

  void increment(String productId) {
    final i = _items.indexWhere((e) => e.product.id == productId);
    if (i >= 0) { _items[i].increment(); notifyListeners(); }
  }

  void decrement(String productId) {
    final i = _items.indexWhere((e) => e.product.id == productId);
    if (i >= 0) {
      if (_items[i].quantite > 1) {
        _items[i].decrement();
      } else {
        _items.removeAt(i);
      }
      notifyListeners();
    }
  }

  void clear() { _items.clear(); notifyListeners(); }
}
