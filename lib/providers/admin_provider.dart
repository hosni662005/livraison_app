import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';

class AdminProvider extends ChangeNotifier {
  final UserRepository _repo;
  AdminProvider({UserRepository? repo}) : _repo = repo ?? UserRepository();

  List<AppUser> users = [];
  List<AppUser> demandes = [];
  bool loading = true;
  String? error;
  UserRole? roleFilter;
  StreamSubscription? _sub;
  StreamSubscription? _demandesSub;

  void listenUsers({UserRole? role}) {
    roleFilter = role;
    loading = true;
    _sub?.cancel();
    final stream = role == null ? _repo.streamAll() : _repo.streamByRole(role);
    _sub = stream.listen((list) {
      users = list;
      loading = false;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    });
  }

  void listenDemandes() {
    _demandesSub?.cancel();
    _demandesSub = _repo.streamDemandes().listen((list) {
      demandes = list;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      notifyListeners();
    });
  }

  Future<void> toggleActif(AppUser u) => _repo.updateActif(u.id, !u.actif);
  Future<void> changeRole(AppUser u, UserRole r) => _repo.updateRole(u.id, r);

  /// Accepter une candidature (active le compte avec son rôle livreur ou vendeur)
  Future<void> accepterDemande(AppUser u) async {
    await _repo.updateDemandeStatut(u.id, statut: 'validee', actif: true);
  }

  /// Refuser une candidature
  Future<void> refuserDemande(AppUser u) async {
    await _repo.updateDemandeStatut(u.id, statut: 'refusee', actif: false);
  }

  // Stats helpers
  Map<String, int> countByRole() {
    final m = <String, int>{};
    for (final u in users) {
      m[u.role.value] = (m[u.role.value] ?? 0) + 1;
    }
    return m;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _demandesSub?.cancel();
    super.dispose();
  }
}
