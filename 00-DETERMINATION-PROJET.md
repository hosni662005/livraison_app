# Détermination du Projet Flutter — Application de Livraison Multi-Rôles
> **Groupe 7 — Conception UML | Octobre 2026 | v1.0**
> Sources : `00-cahier-des-charges.pdf` + `Firebase-Order-Domain-Model` + `Firebase-Client-Registration-Pipeline` + `Role-Based-Use-Case-Model`

---

## 1. Fiche d'identité

| Champ | Valeur |
|---|---|
| **Nom projet** | `livraison_app` |
| **Type** | Application mobile multi-rôles (marketplace + livraison) |
| **Cycle complet** | Catalogue → Panier → Commande → Préparation → Livraison → Suivi temps réel |
| **Frontend** | **Flutter 3.x** |
| **Backend** | **Firebase Authentication** (email/mot de passe) + **Cloud Firestore** |
| **State Management** | `provider` |
| **Navigation** | `go_router` (avec garde de routes par rôle) |
| **Plateformes** | Android + iOS + Web |
| **Paiement v1** | À la livraison uniquement (pas de paiement en ligne) |
| **Hors scope v1** | Paiement en ligne, notifications push, carte interactive, Firebase Storage |

---

## 2. Acteurs (4 rôles)

| # | Acteur | Description | Création du compte |
|---|---|---|---|
| 1 | **Client** | Parcourt catalogue, gère panier, passe et suit ses commandes | **Inscription libre** (`role = client`) — RG-01 |
| 2 | **Vendeur** | Publie produits (CRUD), traite commandes reçues | Créé par **Administrateur** |
| 3 | **Livreur** | S'assigne commandes `prête` et assure `enLivraison → livrée` | Créé par **Administrateur** |
| 4 | **Admin** | Supervise plateforme, gère utilisateurs et statistiques | Créé manuellement (seed Firebase) |

> **RG-01** : L'inscription publique crée **toujours** un Client. Tout autre rôle est attribué par l'Admin.
> **RG-02** : Un compte `actif = false` est bloqué à la connexion.

---

## 3. Architecture technique imposée

```
┌─────────────────────────────────────────────┐
│           Flutter 3.x (Material 3)          │
│  Screens / Widgets  ←  Providers (provider) │
│         ↕                  ↕                │
│    Repositories  ←→  Services (AuthService) │
│         ↕                  ↕                │
│   Firebase Auth  +  Cloud Firestore         │
│         ↕                                  │
│   go_router (garde par rôle) + intl        │
└─────────────────────────────────────────────┘
```

**Dépendances `pubspec.yaml` v1 :**
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.15.0
  provider: ^6.1.0
  go_router: ^13.0.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

**Architecture en couches (NF-06) :**
`models / repositories / providers / screens` + `services / router / utils / widgets`

---

## 4. Arborescence Flutter — Déterminée et Fige

```
livraison_app/
├── lib/
│   ├── main.dart                      # Firebase init + MultiProvider + GoRouter
│   ├── firebase_options.dart          # flutterfire configure
│   ├── models/
│   │   ├── app_user.dart              # AppUser + UserRole enum
│   │   ├── product.dart               # Product + Category enum
│   │   ├── order.dart                 # Order + OrderStatus enum
│   │   ├── order_item.dart            # OrderItem
│   │   └── cart_item.dart             # CartItem (Product + quantite)
│   ├── repositories/
│   │   ├── user_repository.dart       # CRUD users (Firestore users)
│   │   ├── product_repository.dart    # CRUD products + streams par vendeur/categorie
│   │   └── order_repository.dart      # CRUD orders + streams par client/vendeur/livreur
│   ├── services/
│   │   └── auth_service.dart          # Firebase Auth wrapper (register/login/logout/reset)
│   ├── providers/
│   │   ├── auth_provider.dart         # AuthProvider (status, user, error, loading)
│   │   ├── product_provider.dart      # catalogue, filtrage, recherche
│   │   ├── cart_provider.dart         # panier (add/remove/increment/clear)
│   │   ├── order_provider.dart        # commandes + transitions de statut
│   │   └── admin_provider.dart        # stats + gestion utilisateurs
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── common/
│   │   │   ├── splash_screen.dart
│   │   │   ├── profile_screen.dart    # FC-05 / FC-06
│   │   │   └── unauthorized_screen.dart
│   │   ├── client/
│   │   │   ├── client_home.dart       # Shell avec BottomNav
│   │   │   ├── catalogue_screen.dart  # CL-01 (grille + filtre categorie + recherche)
│   │   │   ├── product_detail_screen.dart # CL-02
│   │   │   ├── cart_screen.dart       # CL-03
│   │   │   ├── checkout_screen.dart   # CL-04 (adresse, tel, note, paiement à livraison)
│   │   │   ├── orders_screen.dart     # CL-05
│   │   │   └── order_detail_screen.dart # CL-06 + CL-07 (timeline + annuler si enAttente)
│   │   ├── vendeur/
│   │   │   ├── vendeur_home.dart
│   │   │   ├── dashboard_screen.dart  # VE-01 (CA jour, en attente, nb produits)
│   │   │   ├── products_screen.dart   # VE-02
│   │   │   ├── product_form_screen.dart # VE-03 / VE-04
│   │   │   ├── orders_received_screen.dart # VE-05
│   │   │   └── order_manage_screen.dart # VE-06 / VE-07
│   │   ├── livreur/
│   │   │   ├── livreur_home.dart
│   │   │   ├── available_orders_screen.dart # LI-01
│   │   │   ├── my_deliveries_screen.dart    # LI-03
│   │   │   └── delivery_detail_screen.dart  # LI-04 / LI-05 (lien Maps)
│   │   └── admin/
│   │       ├── admin_home.dart
│   │       ├── users_screen.dart      # AD-01 / AD-02 / AD-03
│   │       ├── all_orders_screen.dart # AD-04
│   │       └── stats_screen.dart      # AD-05
│   ├── widgets/
│   │   ├── product_card.dart
│   │   ├── order_timeline.dart        # timeline OrderStatus avec couleurs
│   │   ├── status_badge.dart
│   │   └── loading_error.dart
│   ├── router/
│   │   └── app_router.dart            # GoRouter + redirect par rôle + garde actif
│   └── utils/
│       ├── validators.dart            # required / email / phone / password
│       ├── constants.dart
│       └── helpers.dart
├── docs/                              # UML exportés
└── pubspec.yaml
```

---

## 5. Modèle de Domaine (UML Classes)

### 5.1 Énumérations

```dart
enum UserRole { client, vendeur, livreur, admin }
// + value, label, homeRoute, fromString()

enum OrderStatus { enAttente, confirmee, enPreparation, prete, enLivraison, livree, annulee }
// + value, label, color

enum Category { plats, boissons, desserts, epicerie, autre }
// + value, label
```

### 5.2 Entités

| Entité | Champs | Méthodes |
|---|---|---|
| **AppUser** | `id, nom, email, telephone, role:UserRole, actif:bool, photoUrl?, dateCreation:DateTime` | `fromMap(id, Map)`, `toMap()`, `copyWith()` |
| **Product** | `id, nom, description, prix:double, imageUrl:String(URL), categorie:String, vendeurId, disponible:bool, dateCreation` | `fromMap`, `toMap`, `copyWith` |
| **Order** | `id, clientId, vendeurId?, livreurId?, items:List<OrderItem>, total:double, statut:OrderStatus, adresseLivraison, telephone, note?, dateCreation, dateMiseAJour` | `fromMap`, `toMap`, `canBeCancelled():bool`, `nextStatus():OrderStatus?` |
| **OrderItem** | `productId, nom, prix, quantite:int, sousTotal:double` | `fromMap(Map)`, `toMap()` |
| **CartItem** | `product:Product, quantite:int, sousTotal:double` | `increment()`, `decrement()` |

**Relations :** AppUser(1) — (*)Product via `vendeurId` | AppUser(1) — (*)Order via `clientId/vendeurId/livreurId` | Order(1) — (*)OrderItem | CartItem encapsule Product

---

## 6. Collections Firestore (3 collections)

### `users` — document id = `uid` Firebase Auth
```json
{
  "nom": "string",
  "email": "string",
  "telephone": "string",
  "role": "client | vendeur | livreur | admin",
  "actif": true,
  "photoUrl": "string | null",
  "dateCreation": "Timestamp"
}
```

### `products`
```json
{
  "nom": "string",
  "description": "string",
  "prix": 12.5,
  "imageUrl": "https://...",
  "categorie": "plats | boissons | desserts | epicerie | autre",
  "vendeurId": "uid",
  "disponible": true,
  "dateCreation": "Timestamp"
}
```

### `orders`
```json
{
  "clientId": "uid",
  "vendeurId": "uid | null",
  "livreurId": "uid | null",
  "items": [{ "productId": "...", "nom": "...", "prix": 10.0, "quantite": 2, "sousTotal": 20.0 }],
  "total": 20.0,
  "statut": "enAttente | confirmee | enPreparation | prete | enLivraison | livree | annulee",
  "adresseLivraison": "string",
  "telephone": "string",
  "note": "string | null",
  "dateCreation": "Timestamp",
  "dateMiseAJour": "Timestamp"
}
```

**Pipelines temps réel :** `snapshots()` Firestore → Repository Stream → Provider → Consumer (catalogue <2s, suivi commande live)

---

## 7. Exigences Fonctionnelles — Matrice Déterminée

### 7.1 Communes (FC)

| ID | Exigence | Écran / Logique |
|---|---|---|
| FC-01 | S'inscrire (nom, téléphone, e-mail, mdp) | `RegisterScreen` → RG-01 force `client` |
| FC-02 | Se connecter (e-mail + mdp) | `LoginScreen` → vérif `actif==true` sinon blocage RG-02 |
| FC-03 | Se déconnecter | AppBar action sur tous les shells |
| FC-04 | Réinitialiser mdp (lien e-mail) | `ForgotPasswordScreen` → `sendPasswordResetEmail` |
| FC-05 | Consulter son profil | `ProfileScreen` |
| FC-06 | Modifier profil (nom, téléphone) | `ProfileScreen` (edit) |
| FC-07 | Redirection auto vers espace du rôle | `app_router.dart` redirect |
| FC-08 | Garde de routes par rôle | `go_router` redirect : un rôle ne voit que son espace |

### 7.2 Client (CL)

| ID | Exigence | Implémentation |
|---|---|---|
| CL-01 | Catalogue grille + filtre catégorie + recherche | `CatalogueScreen` + `ProductProvider` (stream + filter local) |
| CL-02 | Détail produit (image, prix, description, dispo) | `ProductDetailScreen` |
| CL-03 | Panier add/remove/quantités | `CartProvider` + `CartScreen` |
| CL-04 | Passer commande (adresse, tel, note, paiement à livraison RG-07) | `CheckoutScreen` → crée `Order(enAttente)` |
| CL-05 | Liste ses commandes | `OrdersScreen` stream `where clientId==uid` |
| CL-06 | Détail + timeline statut | `OrderDetailScreen` + `OrderTimeline` |
| CL-07 | Annuler si `enAttente` | RG-03 + `canBeCancelled()` |

### 7.3 Vendeur (VE)

| ID | Exigence | Implémentation |
|---|---|---|
| VE-01 | Dashboard (CA jour, commandes en attente, nb produits) | `DashboardScreen` (agrégations Firestore) |
| VE-02 | Lister ses produits | `where vendeurId==uid` |
| VE-03 | Créer produit (nom, desc, prix, imageUrl, catégorie, dispo) | RG-08 : imageUrl = URL texte |
| VE-04 | Modifier / supprimer produit | `ProductFormScreen` |
| VE-05 | Lister commandes reçues (filtrées par ses produits) | `where vendeurId==uid` |
| VE-06 | Faire évoluer `enAttente → confirmee → enPreparation → prete` | RG-04 + RG-06 séquentiel |
| VE-07 | Annuler commande `enAttente` | RG-03 |

### 7.4 Livreur (LI)

| ID | Exigence | Implémentation |
|---|---|---|
| LI-01 | Lister commandes `prete` non assignées | `where statut==prete && livreurId==null` |
| LI-02 | S'assigner une commande | `update livreurId=uid` — RG-05 |
| LI-03 | Lister ses livraisons assignées | `where livreurId==uid && statut in [prete,enLivraison,livree]` |
| LI-04 | `prete → enLivraison → livree` | RG-06 séquentiel |
| LI-05 | Détail livraison (adresse, tel client, lien Maps) | `launchUrl("https://maps.google.com/?q=adresse")` |

### 7.5 Admin (AD)

| ID | Exigence | Implémentation |
|---|---|---|
| AD-01 | Lister tous les users (filtre par rôle) | `UsersScreen` + filtre `role` |
| AD-02 | Activer/désactiver compte (`actif`) | Switch → `update actif` |
| AD-03 | Changer rôle | Dropdown `UserRole` |
| AD-04 | Lister toutes les commandes (filtre statut) | `AllOrdersScreen` |
| AD-05 | Statistiques (nb users par rôle, commandes par statut, CA global) | `StatsScreen` |

---

## 8. Cycle de Vie Commande + Règles RG

```
enAttente ──→ confirmee ──→ enPreparation ──→ prete ──→ enLivraison ──→ livree
    │              │
    └────→ annulee ←┘  (RG-03 : annulation seulement depuis enAttente/confirmee
                         par Client / Vendeur / Admin)
```

| Règle | Énoncé | Contrôle |
|---|---|---|
| RG-01 | Inscription publique → `client` uniquement | `AuthService.register` force role |
| RG-02 | `actif=false` bloqué à la connexion | `AuthProvider` + garde router + Firestore rules |
| RG-03 | Annulation seulement si `enAttente` (ou `confirmee` selon CDC p.3) | `Order.canBeCancelled()` + rules |
| RG-04 | Seul vendeur concerné : `enAttente→confirmee→enPreparation→prete` | Vérif `vendeurId==uid` |
| RG-05 | Seul livreur peut s'assigner `prete` non assignée | Vérif `livreurId==null && statut==prete` |
| RG-06 | Transitions séquentielles, pas de retour arrière | `Order.nextStatus()` |
| RG-07 | Paiement à la livraison | Pas de gateway, champ info uniquement |
| RG-08 | `imageUrl` = URL texte (pas de Storage v1) | `TextFormField` URL |

**Matrice transitions autorisées :**

| Depuis | Vers | Acteur | Méthode |
|---|---|---|---|
| enAttente | confirmee | Vendeur | `nextStatus()` |
| confirmee | enPreparation | Vendeur | `nextStatus()` |
| enPreparation | prete | Vendeur | `nextStatus()` |
| prete | enLivraison | Livreur (après assignation) | `nextStatus()` |
| enLivraison | livree | Livreur | `nextStatus()` |
| enAttente/confirmee | annulee | Client/Vendeur/Admin | `canBeCancelled()` |

---

## 9. Navigation & Garde de Routes (`go_router`)

```dart
// app_router.dart — principe
GoRouter(
  redirect: (ctx, state) {
    final user = authProvider.appUser;
    if (user == null) return ['/login','/register','/forgot'].contains(state.matchedLocation) ? null : '/login';
    if (!user.actif) { signOut(); return '/login'; } // RG-02
    // FC-07 + FC-08 : redirection par rôle
    final home = user.role.homeRoute; // /client, /vendeur, /livreur, /admin
    if (state.matchedLocation == '/login' || state.matchedLocation == '/') return home;
    if (!state.matchedLocation.startsWith(home) && !state.matchedLocation.startsWith('/profile')) return home;
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_,__) => '/login'),
    GoRoute(path: '/login', builder: (_,__) => LoginScreen()),
    GoRoute(path: '/register', builder: (_,__) => RegisterScreen()),
    GoRoute(path: '/forgot', builder: (_,__) => ForgotPasswordScreen()),
    ShellRoute(builder: (_,__,child) => ClientHome(child: child), routes: [/* /client/... */]),
    ShellRoute(builder: (_,__,child) => VendeurHome(child: child), routes: [/* /vendeur/... */]),
    ShellRoute(builder: (_,__,child) => LivreurHome(child: child), routes: [/* /livreur/... */]),
    ShellRoute(builder: (_,__,child) => AdminHome(child: child), routes: [/* /admin/... */]),
  ],
)
```

### Pipeline Inscription Client (séquence figée)

```
Client saisit (nom, tel, email, mdp)
  → Validators (required/email/phone/password)
  → AuthProvider.register() [loading=true]
    → AuthService.register(email, mdp) → FirebaseAuth.createUserWithEmailAndPassword → uid
    → UserRepository.createUser(AppUser{id:uid, role:client, actif:true})
      → Firestore set(users/{uid}, {nom, email, telephone, role:client, actif:true, dateCreation})
  → AuthProvider → status=authenticated → go_router redirect → /client → Catalogue
```

---

## 10. Sécurité — Règles Firestore (à déployer)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuth() { return request.auth != null; }
    function myRole() { return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role; }
    function isActive() { return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.actif == true; }

    match /users/{uid} {
      allow read: if isAuth() && isActive();
      allow create: if isAuth() && request.resource.data.role == 'client'; // RG-01
      allow update: if isAuth() && isActive() && (request.auth.uid == uid || myRole() == 'admin');
    }
    match /products/{id} {
      allow read: if isAuth() && isActive();
      allow create, update, delete: if isAuth() && isActive() && myRole() in ['vendeur','admin'];
    }
    match /orders/{id} {
      allow read: if isAuth() && isActive();
      allow create: if isAuth() && isActive() && request.resource.data.clientId == request.auth.uid;
      allow update: if isAuth() && isActive() && (
        myRole() == 'admin' ||
        resource.data.clientId == request.auth.uid ||
        resource.data.vendeurId == request.auth.uid ||
        resource.data.livreurId == request.auth.uid
      );
    }
  }
}
```

---

## 11. Exigences Non Fonctionnelles

| Catégorie | Exigence | Réponse projet |
|---|---|---|
| ⚡ Performance | Catalogue <2s, streams temps réel | `snapshots()` + pagination si >50 produits |
| 🔒 Sécurité | Auth Firebase, règles par rôle, `actif=false` bloqué | Rules ci-dessus + garde router |
| 📡 Disponibilité | Online, messages erreur si hors ligne | `try/catch` + SnackBar + `snapshot.hasError` |
| 🎨 Ergonomie | Material 3, onglets, feedback | `ThemeData(useMaterial3:true)` + SnackBar/loaders |
| 📱 Compatibilité | Android + iOS + Web | Flutter natif |
| 🔧 Maintenabilité | Couches models/repositories/providers/screens | Arborescence §4 |

---

## 12. Plan de Réalisation (4 Sprints)

| Sprint | Objectif | Livrables |
|---|---|---|
| **S1 — Fondations** | Init Firebase, models, enums, repositories, Auth | `main.dart`, `models/`, `repositories/`, `services/auth_service`, `providers/auth_provider`, `router`, `screens/auth` |
| **S2 — Client** | Catalogue → Panier → Commande → Suivi | `providers/product+cart+order`, `screens/client/*`, `widgets/*` |
| **S3 — Vendeur & Livreur** | CRUD produits, dashboard, flux statuts | `screens/vendeur/*`, `screens/livreur/*` |
| **S4 — Admin & Finition** | Gestion users, stats, rules, polish | `screens/admin/*`, `firestore.rules`, tests, Material 3 polish |

---

## 13. Prochaine étape

Le dossier `C:\livraison_app` est vide. Je peux maintenant :

1. **Scaffolder le projet Flutter complet** (`flutter create` + arborescence + `pubspec.yaml` + tous les fichiers `lib/` ci-dessus prêts à compiler)
2. Ou générer uniquement la **structure de dossiers + fichiers vides** pour que tu complètes

> Dis-moi : **« scaffold complet »** et je génère tout le code source v1 (models, repositories, providers, screens, router) d'un seul tenant.
