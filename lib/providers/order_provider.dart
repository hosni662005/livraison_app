import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repo;
  OrderProvider({OrderRepository? repo}) : _repo = repo ?? OrderRepository();

  List<Order> orders = [];
  bool loading = true;
  String? error;
  StreamSubscription? _sub;

  void listenTo(Stream<List<Order>> stream) {
    loading = true;
    error = null;
    notifyListeners();
    _sub?.cancel();
    _sub = stream.listen((list) {
      orders = list;
      loading = false;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    });
  }

  void listenClient(String clientId) => listenTo(_repo.streamByClient(clientId));
  void listenVendeur(String vendeurId) => listenTo(_repo.streamByVendeur(vendeurId));
  void listenLivreur(String livreurId) => listenTo(_repo.streamByLivreur(livreurId));
  void listenAll() => listenTo(_repo.streamAll());
  void listenAvailable() => listenTo(_repo.streamAvailable());

  Future<String> create(Order order) => _repo.create(order);

  Future<void> advanceStatus(String orderId, OrderStatus current) async {
    final next = _nextFor(current);
    if (next == null) throw Exception('Aucune transition depuis ${current.label}');
    await _repo.updateStatus(orderId, next);
  }

  Future<void> cancel(String orderId) => _repo.cancel(orderId);
  Future<void> assignToMe(String orderId, String livreurId) =>
      _repo.assignLivreur(orderId, livreurId);

  OrderStatus? _nextFor(OrderStatus s) {
    switch (s) {
      case OrderStatus.enAttente: return OrderStatus.confirmee;
      case OrderStatus.confirmee: return OrderStatus.enPreparation;
      case OrderStatus.enPreparation: return OrderStatus.prete;
      case OrderStatus.prete: return OrderStatus.enLivraison;
      case OrderStatus.enLivraison: return OrderStatus.livree;
      default: return null;
    }
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
