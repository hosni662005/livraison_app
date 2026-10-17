# Livraison App — Groupe 7 · Flutter + Firebase

> Application de livraison multi-rôles · Catalogue → Panier → Commande → Préparation → Livraison → Suivi temps réel

## Stack

| Couche | Techno |
|---|---|
| Frontend | Flutter 3.x · Material 3 |
| State | `provider` |
| Navigation | `go_router` (garde par rôle FC-08 + RG-02) |
| Backend | Firebase Auth (email/mdp) + Cloud Firestore |
| Plateformes | Android + iOS + Web |
| Langue | `intl` |

## Démarrage (cette machine n'a pas Flutter installé)

```bash
# 1. Installer Flutter SDK https://docs.flutter.dev/get-started/install
flutter --version

# 2. Générer les dossiers plateformes (android/ios/web) à la racine du projet
cd C:\livraison_app
flutter create . --project-name livraison_app --org com.groupe7.livraison

# 3. Configurer Firebase (remplace lib/firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure --project=<ton-project-id>

# 4. Installer deps + lancer
flutter pub get
flutter run

# 5. Déployer les règles Firestore
firebase deploy --only firestore:rules   # fichier firestore.rules à la racine
```

> `lib/firebase_options.dart` est un placeholder `TODO` — `flutterfire configure` le régénère.

## Comptes & rôles (RG-01 / RG-02)

| Rôle | Création | Home |
|---|---|---|
| `client` | Inscription libre (Register) | `/client` |
| `vendeur` | Par Admin (Users → changer rôle) | `/vendeur` |
| `livreur` | Par Admin | `/livreur` |
| `admin` | Seed manuel Firestore `users/{uid}` avec `role=admin` | `/admin` |

Seed admin : crée un compte via Register puis dans la console Firestore passe `users/{uid}.role = admin`.

## Collections Firestore (3)

`users` (`id = uid Auth`), `products`, `orders` — voir `firestore.rules` pour les règles par rôle.

## Cycle commande (RG-03 → RG-06)

```
enAttente → confirmee → enPreparation → prete → enLivraison → livree
    ↘ annulee (depuis enAttente/confirmee par Client/Vendeur/Admin)
```

Transitions séquentielles (`Order.nextStatus()`), `canBeCancelled()`.

## Arborescence `lib/`

```
lib/
├── main.dart
├── firebase_options.dart
├── models/        app_user.dart (UserRole), product.dart (Category), order.dart (OrderStatus), order_item.dart, cart_item.dart
├── repositories/  user/product/order_repository.dart (streams Firestore)
├── services/      auth_service.dart
├── providers/     auth/product/cart/order/admin
├── router/        app_router.dart (redirect par rôle)
├── screens/
│   ├── auth/      login, register, forgot_password
│   ├── common/    splash, profile, unauthorized
│   ├── client/    catalogue, product_detail, cart, checkout, orders, order_detail
│   ├── vendeur/   dashboard, products, product_form, orders_received, order_manage
│   ├── livreur/   available_orders, my_deliveries, delivery_detail (+ lien Maps)
│   └── admin/     users, all_orders, stats
├── widgets/       product_card, order_timeline, status_badge, loading_error
└── utils/         validators, constants, helpers
```

## Règles Firestore

`firestore.rules` implémente RG-01 (inscription → client), RG-02 (actif), RG-04/05/06 (transitions par rôle). Déploie avec `firebase deploy`.

## Exigences couvertes

FC-01..08, CL-01..07, VE-01..07, LI-01..05, AD-01..05, RG-01..08, NF performance/sécurité/ergonomie.

## Docs

- `00-DETERMINATION-PROJET.md` — détermination complète du projet (CDC, modèles, collections, sprints)
- `firestore.rules` — règles sécurité
- `analysis_options.yaml` — lints
