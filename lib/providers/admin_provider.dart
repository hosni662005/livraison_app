import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';

class AdminProvider extends ChangeNotifier {
  final UserRepository _repo;
  AdminProvider({UserRepository? repo}) : _repo = repo ?? UserRepository();

  List<AppUser> users = [];
  bool loading = true;
  String? error;
  UserRole? roleFilter;
  StreamSubscription? _sub;

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

  Future<void> toggleActif(AppUser u) => _repo.updateActif(u.id, !u.actif);
  Future<void> changeRole(AppUser u, UserRole r) => _repo.updateRole(u.id, r);

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
    super.dispose();
  }
}
