import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/app_user.dart';

// Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/common/splash_screen.dart';
import '../screens/common/profile_screen.dart';
import '../screens/common/unauthorized_screen.dart';

// Client
import '../screens/client/client_home.dart';
import '../screens/client/catalogue_screen.dart';
import '../screens/client/product_detail_screen.dart';
import '../screens/client/cart_screen.dart';
import '../screens/client/checkout_screen.dart';
import '../screens/client/orders_screen.dart';
import '../screens/client/order_detail_screen.dart';

// Vendeur
import '../screens/vendeur/vendeur_home.dart';
import '../screens/vendeur/dashboard_screen.dart';
import '../screens/vendeur/products_screen.dart';
import '../screens/vendeur/product_form_screen.dart';
import '../screens/vendeur/orders_received_screen.dart';
import '../screens/vendeur/order_manage_screen.dart';

// Livreur
import '../screens/livreur/livreur_home.dart';
import '../screens/livreur/available_orders_screen.dart';
import '../screens/livreur/my_deliveries_screen.dart';
import '../screens/livreur/delivery_detail_screen.dart';

// Admin
import '../screens/admin/admin_home.dart';
import '../screens/admin/users_screen.dart';
import '../screens/admin/all_orders_screen.dart';
import '../screens/admin/stats_screen.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (ctx, state) {
      final loc = state.matchedLocation;
      final isAuthRoute = ['/login', '/register', '/forgot'].contains(loc);
      final isSplash = loc == '/';

      // Encore en chargement initial — on reste sur Splash
      if (auth.status == AuthStatus.initial || auth.status == AuthStatus.loading) {
        return isSplash ? null : '/';
      }
      // Erreur (ex: Firestore indisponible) → on force vers login
      if (auth.status == AuthStatus.error) {
        return isAuthRoute ? null : '/login';
      }
      // Non authentifié — Splash et routes auth sont autorisées, sinon → /login
      if (auth.status != AuthStatus.authenticated || auth.appUser == null) {
        if (isAuthRoute) return null;
        if (isSplash) return '/login';
        return '/login';
      }
      final user = auth.appUser!;
      // RG-02 : compte désactivé déjà géré dans AuthProvider (logout), garde-fou
      if (!user.actif) return '/login';

      // Authentifié sur /login ou /register ou / => redirige vers son home
      if (isAuthRoute || isSplash || loc == '/login' || loc == '/') {
        return user.role.homeRoute;
      }
      // FC-08 : garde de rôle — /profile autorisé à tous
      if (loc.startsWith('/profile')) return null;
      if (!loc.startsWith(user.role.homeRoute)) return user.role.homeRoute;

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/unauthorized', builder: (_, __) => const UnauthorizedScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

      // ── Client ──
      ShellRoute(
        builder: (_, __, child) => ClientHome(child: child),
        routes: [
          GoRoute(path: '/client', builder: (_, __) => const CatalogueScreen()),
          GoRoute(path: '/client/product/:id', builder: (_, s) => ProductDetailScreen(productId: s.pathParameters['id']!)),
          GoRoute(path: '/client/cart', builder: (_, __) => const CartScreen()),
          GoRoute(path: '/client/checkout', builder: (_, __) => const CheckoutScreen()),
          GoRoute(path: '/client/orders', builder: (_, __) => const OrdersScreen()),
          GoRoute(path: '/client/orders/:id', builder: (_, s) => OrderDetailScreen(orderId: s.pathParameters['id']!)),
        ],
      ),

      // ── Vendeur ──
      ShellRoute(
        builder: (_, __, child) => VendeurHome(child: child),
        routes: [
          GoRoute(path: '/vendeur', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/vendeur/products', builder: (_, __) => const ProductsScreen()),
          GoRoute(path: '/vendeur/products/new', builder: (_, __) => const ProductFormScreen()),
          GoRoute(path: '/vendeur/products/:id/edit', builder: (_, s) => ProductFormScreen(productId: s.pathParameters['id'])),
          GoRoute(path: '/vendeur/orders', builder: (_, __) => const OrdersReceivedScreen()),
          GoRoute(path: '/vendeur/orders/:id', builder: (_, s) => OrderManageScreen(orderId: s.pathParameters['id']!)),
        ],
      ),

      // ── Livreur ──
      ShellRoute(
        builder: (_, __, child) => LivreurHome(child: child),
        routes: [
          GoRoute(path: '/livreur', builder: (_, __) => const AvailableOrdersScreen()),
          GoRoute(path: '/livreur/available', builder: (_, __) => const AvailableOrdersScreen()),
          GoRoute(path: '/livreur/deliveries', builder: (_, __) => const MyDeliveriesScreen()),
          GoRoute(path: '/livreur/deliveries/:id', builder: (_, s) => DeliveryDetailScreen(orderId: s.pathParameters['id']!)),
        ],
      ),

      // ── Admin ──
      ShellRoute(
        builder: (_, __, child) => AdminHome(child: child),
        routes: [
          GoRoute(path: '/admin', builder: (_, __) => const UsersScreen()),
          GoRoute(path: '/admin/users', builder: (_, __) => const UsersScreen()),
          GoRoute(path: '/admin/orders', builder: (_, __) => const AllOrdersScreen()),
          GoRoute(path: '/admin/orders/:id', builder: (_, s) => OrderDetailScreen(orderId: s.pathParameters['id']!)),
          GoRoute(path: '/admin/stats', builder: (_, __) => const StatsScreen()),
        ],
      ),
    ],
    errorBuilder: (_, s) => Scaffold(body: Center(child: Text('Page introuvable: ${s.uri}'))),
  );
}
