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

  const AppUser({
    required this.id,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.role,
    required this.actif,
    this.photoUrl,
    required this.dateCreation,
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
      };

  AppUser copyWith({
    String? nom,
    String? email,
    String? telephone,
    UserRole? role,
    bool? actif,
    String? photoUrl,
    DateTime? dateCreation,
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
      );

  static DateTime _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
