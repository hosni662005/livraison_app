import 'package:cloud_firestore/cloud_firestore.dart';

/// Rôles — RG-01 : inscription publique => toujours [client]
enum UserRole {
  client('client', 'Client', '/client'),
  vendeur('vendeur', 'Vendeur', '/vendeur'),
  livreur('livreur', 'Livreur', '/livreur'),
  admin('admin', 'Admin', '/admin');

  const UserRole(this.value, this.label, this.homeRoute);
  final String value;
  final String label;
  final String homeRoute;

  static UserRole fromString(String v) =>
      UserRole.values.firstWhere((e) => e.value == v, orElse: () => UserRole.client);
}

class AppUser {
  final String id;
  final String nom;
  final String email;
  final String telephone;
  final UserRole role;
  final bool actif;
  final String? photoUrl;
  final DateTime dateCreation;
  final String? statutDemande; // 'enAttente', 'validee', 'refusee'
  final String? vehicule; // pour livreur (ex: Moto, Vélo, Voiture)
  final String? zoneLivraison; // pour livreur (ville ou zone)
  final String? nomRestaurant; // pour restaurant / vendeur
  final String? adresseRestaurant; // pour restaurant / vendeur

  const AppUser({
    required this.id,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.role,
    required this.actif,
    this.photoUrl,
    required this.dateCreation,
    this.statutDemande,
    this.vehicule,
    this.zoneLivraison,
    this.nomRestaurant,
    this.adresseRestaurant,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> m) {
    return AppUser(
      id: id,
      nom: m['nom'] as String? ?? '',
      email: m['email'] as String? ?? '',
      telephone: m['telephone'] as String? ?? '',
      role: UserRole.fromString(m['role'] as String? ?? 'client'),
      actif: m['actif'] as bool? ?? true,
      photoUrl: m['photoUrl'] as String?,
      dateCreation: _toDate(m['dateCreation']),
      statutDemande: m['statutDemande'] as String?,
      vehicule: m['vehicule'] as String?,
      zoneLivraison: m['zoneLivraison'] as String?,
      nomRestaurant: m['nomRestaurant'] as String?,
      adresseRestaurant: m['adresseRestaurant'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'email': email,
        'telephone': telephone,
        'role': role.value,
        'actif': actif,
        'photoUrl': photoUrl,
        'dateCreation': Timestamp.fromDate(dateCreation),
        if (statutDemande != null) 'statutDemande': statutDemande,
        if (vehicule != null) 'vehicule': vehicule,
        if (zoneLivraison != null) 'zoneLivraison': zoneLivraison,
        if (nomRestaurant != null) 'nomRestaurant': nomRestaurant,
        if (adresseRestaurant != null) 'adresseRestaurant': adresseRestaurant,
      };

  AppUser copyWith({
    String? nom,
    String? email,
    String? telephone,
    UserRole? role,
    bool? actif,
    String? photoUrl,
    DateTime? dateCreation,
    String? statutDemande,
    String? vehicule,
    String? zoneLivraison,
    String? nomRestaurant,
    String? adresseRestaurant,
  }) =>
      AppUser(
        id: id,
        nom: nom ?? this.nom,
        email: email ?? this.email,
        telephone: telephone ?? this.telephone,
        role: role ?? this.role,
        actif: actif ?? this.actif,
        photoUrl: photoUrl ?? this.photoUrl,
        dateCreation: dateCreation ?? this.dateCreation,
        statutDemande: statutDemande ?? this.statutDemande,
        vehicule: vehicule ?? this.vehicule,
        zoneLivraison: zoneLivraison ?? this.zoneLivraison,
        nomRestaurant: nomRestaurant ?? this.nomRestaurant,
        adresseRestaurant: adresseRestaurant ?? this.adresseRestaurant,
      );

  static DateTime _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
