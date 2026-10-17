import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../utils/constants.dart';

class UserRepository {
  final _col = FirebaseFirestore.instance.collection(AppConstants.collections.users);

  Future<void> createUser(AppUser user) => _col.doc(user.id).set(user.toMap());

  Future<AppUser?> getById(String uid) async {
    final d = await _col.doc(uid).get();
    if (!d.exists || d.data() == null) return null;
    return AppUser.fromMap(d.id, d.data()!);
  }

  Stream<AppUser?> streamById(String uid) =>
      _col.doc(uid).snapshots().map((d) => d.data() == null ? null : AppUser.fromMap(d.id, d.data()!));

  Stream<List<AppUser>> streamAll() => _col.snapshots().map(
      (s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());

  Stream<List<AppUser>> streamByRole(UserRole role) => _col
      .where('role', isEqualTo: role.value)
      .snapshots()
      .map((s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());

  Future<void> updateActif(String uid, bool actif) => _col.doc(uid).update({'actif': actif});

  Future<void> updateRole(String uid, UserRole role) =>
      _col.doc(uid).update({'role': role.value});

  Future<void> updateProfile(String uid, {String? nom, String? telephone, String? photoUrl}) {
    final m = <String, dynamic>{};
    if (nom != null) m['nom'] = nom;
    if (telephone != null) m['telephone'] = telephone;
    if (photoUrl != null) m['photoUrl'] = photoUrl;
    return _col.doc(uid).update(m);
  }
}
