import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserRepository _userRepo;

  AuthProvider({AuthService? authService, UserRepository? userRepo})
      : _authService = authService ?? AuthService(),
        _userRepo = userRepo ?? UserRepository() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
    _onAuthStateChanged(_authService.currentUser);
    // Sécurité : si Firebase ne répond pas (config / Firestore manquant), on sort du Splash après 5s
    Future.delayed(const Duration(seconds: 5), () {
      if (status == AuthStatus.initial) {
        debugPrint('Auth timeout -> passage en unauthenticated');
        status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });
  }

  AuthStatus status = AuthStatus.initial;
  AppUser? appUser;
  String? error;
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  Future<void> _onAuthStateChanged(User? fbUser) async {
    if (fbUser == null) {
      appUser = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    status = AuthStatus.loading;
    notifyListeners();
    try {
      final u = await _userRepo.getById(fbUser.uid);
      if (u == null) {
        // Compte Auth sans doc users -> déconnexion
        await _authService.logout();
        appUser = null;
        status = AuthStatus.unauthenticated;
      } else if (!u.actif) {
        // RG-02 : compte désactivé
        await _authService.logout();
        appUser = null;
        status = AuthStatus.unauthenticated;
        error = 'Votre compte a été désactivé. Contactez l\'administrateur.';
      } else {
        appUser = u;
        status = AuthStatus.authenticated;
        error = null;
      }
    } catch (e) {
      error = e.toString();
      status = AuthStatus.error;
    }
    notifyListeners();
  }

  /// FC-01 — RG-01 : inscription publique => toujours role client + actif true
  Future<bool> register({
    required String nom,
    required String email,
    required String telephone,
    required String password,
  }) async {
    status = AuthStatus.loading;
    error = null;
    notifyListeners();
    try {
      final cred = await _authService.register(email, password);
      final uid = cred.user!.uid;
      final newUser = AppUser(
        id: uid,
        nom: nom.trim(),
        email: email.trim(),
        telephone: telephone.trim(),
        role: UserRole.client,
        actif: true,
        dateCreation: DateTime.now(),
      );
      await _userRepo.createUser(newUser);
      appUser = newUser;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      error = _mapAuthError(e);
      status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString();
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    status = AuthStatus.loading;
    error = null;
    notifyListeners();
    try {
      await _authService.login(email, password);
      // _onAuthStateChanged fera la vérif actif + chargement AppUser
      return true;
    } on FirebaseAuthException catch (e) {
      error = _mapAuthError(e);
      status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString();
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    appUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordReset(email);
      return true;
    } on FirebaseAuthException catch (e) {
      error = _mapAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    final fb = _authService.currentUser;
    if (fb == null) return;
    appUser = await _userRepo.getById(fb.uid);
    notifyListeners();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet e-mail est déjà utilisé.';
      case 'invalid-email':
        return 'E-mail invalide.';
      case 'weak-password':
        return 'Mot de passe trop faible.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou mot de passe incorrect.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      default:
        return e.message ?? 'Erreur d\'authentification.';
    }
  }
}
