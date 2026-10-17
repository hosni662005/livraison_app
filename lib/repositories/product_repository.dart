import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../utils/constants.dart';

class ProductRepository {
  final _col = FirebaseFirestore.instance.collection(AppConstants.collections.products);

  Stream<List<Product>> streamAll() => _col
      .orderBy('dateCreation', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Product.fromMap(d.id, d.data())).toList());

  Stream<List<Product>> streamByVendeur(String vendeurId) => _col
      .where('vendeurId', isEqualTo: vendeurId)
      .snapshots()
      .map((s) => s.docs.map((d) => Product.fromMap(d.id, d.data())).toList());

  Stream<List<Product>> streamByCategorie(String cat) => _col
      .where('categorie', isEqualTo: cat)
      .snapshots()
      .map((s) => s.docs.map((d) => Product.fromMap(d.id, d.data())).toList());

  Future<Product?> getById(String id) async {
    final d = await _col.doc(id).get();
    if (!d.exists || d.data() == null) return null;
    return Product.fromMap(d.id, d.data()!);
  }

  Future<String> create(Product p) async {
    final doc = await _col.add(p.toMap());
    return doc.id;
  }

  Future<void> update(String id, Map<String, dynamic> data) => _col.doc(id).update(data);

  Future<void> delete(String id) => _col.doc(id).delete();
}
