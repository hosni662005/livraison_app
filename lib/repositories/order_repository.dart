import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';
import '../utils/constants.dart';

class OrderRepository {
  final _col = FirebaseFirestore.instance.collection(AppConstants.collections.orders);

  Stream<List<Order>> streamAll() => _col
      .orderBy('dateCreation', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Order.fromMap(d.id, d.data())).toList());

  Stream<List<Order>> streamByClient(String clientId) => _col
      .where('clientId', isEqualTo: clientId)
      .orderBy('dateCreation', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Order.fromMap(d.id, d.data())).toList());

  Stream<List<Order>> streamByVendeur(String vendeurId) => _col
      .where('vendeurId', isEqualTo: vendeurId)
      .orderBy('dateCreation', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Order.fromMap(d.id, d.data())).toList());

  Stream<List<Order>> streamByLivreur(String livreurId) => _col
      .where('livreurId', isEqualTo: livreurId)
      .orderBy('dateCreation', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Order.fromMap(d.id, d.data())).toList());

  /// LI-01 : prêtes non assignées
  Stream<List<Order>> streamAvailable() => _col
      .where('statut', isEqualTo: OrderStatus.prete.value)
      .where('livreurId', isNull: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Order.fromMap(d.id, d.data())).toList());

  Future<Order?> getById(String id) async {
    final d = await _col.doc(id).get();
    if (!d.exists || d.data() == null) return null;
    return Order.fromMap(d.id, d.data()!);
  }

  Stream<Order?> streamById(String id) =>
      _col.doc(id).snapshots().map((d) => d.data() == null ? null : Order.fromMap(d.id, d.data()!));

  Future<String> create(Order order) async {
    final doc = await _col.add(order.toMap());
    return doc.id;
  }

  Future<void> updateStatus(String id, OrderStatus status) =>
      _col.doc(id).update({'statut': status.value, 'dateMiseAJour': Timestamp.now()});

  Future<void> assignLivreur(String orderId, String livreurId) => _col.doc(orderId).update({
        'livreurId': livreurId,
        'statut': OrderStatus.enLivraison.value,
        'dateMiseAJour': Timestamp.now(),
      });

  Future<void> cancel(String id) =>
      _col.doc(id).update({'statut': OrderStatus.annulee.value, 'dateMiseAJour': Timestamp.now()});
}
