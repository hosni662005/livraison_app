import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repo;
  ProductProvider({ProductRepository? repo}) : _repo = repo ?? ProductRepository();

  List<Product> _all = [];
  List<Product> filtered = [];
  String searchQuery = '';
  String? categorieFilter;
  bool loading = true;
  String? error;
  StreamSubscription? _sub;

  void initStream() {
    loading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _repo.streamAll().listen((list) {
      _all = list;
      _applyFilters();
      loading = false;
      error = null;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    });
  }

  void initForVendeur(String vendeurId) {
    loading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _repo.streamByVendeur(vendeurId).listen((list) {
      _all = list;
      _applyFilters();
      loading = false;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    });
  }

  void setSearch(String q) {
    searchQuery = q;
    _applyFilters();
    notifyListeners();
  }

  void setCategorie(String? cat) {
    categorieFilter = cat;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    filtered = _all.where((p) {
      final matchSearch = searchQuery.isEmpty ||
          p.nom.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(searchQuery.toLowerCase());
      final matchCat = categorieFilter == null || p.categorie == categorieFilter;
      return matchSearch && matchCat;
    }).toList();
  }

  Future<String> create(Product p) => _repo.create(p);
  Future<void> update(String id, Map<String, dynamic> data) => _repo.update(id, data);
  Future<void> delete(String id) => _repo.delete(id);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
