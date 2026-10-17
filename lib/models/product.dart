import 'package:cloud_firestore/cloud_firestore.dart';

enum Category {
  plats('plats', 'Plats'),
  boissons('boissons', 'Boissons'),
  desserts('desserts', 'Desserts'),
  epicerie('epicerie', 'Épicerie'),
  autre('autre', 'Autre');

  const Category(this.value, this.label);
  final String value;
  final String label;

  static Category fromString(String v) =>
      Category.values.firstWhere((e) => e.value == v, orElse: () => Category.autre);
}

class Product {
  final String id;
  final String nom;
  final String description;
  final double prix;
  final String imageUrl; // RG-08 : URL texte, pas de Storage en v1
  final String categorie;
  final String vendeurId;
  final bool disponible;
  final DateTime dateCreation;

  const Product({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.imageUrl,
    required this.categorie,
    required this.vendeurId,
    required this.disponible,
    required this.dateCreation,
  });

  factory Product.fromMap(String id, Map<String, dynamic> m) {
    return Product(
      id: id,
      nom: m['nom'] as String? ?? '',
      description: m['description'] as String? ?? '',
      prix: (m['prix'] as num? ?? 0).toDouble(),
      imageUrl: m['imageUrl'] as String? ?? '',
      categorie: m['categorie'] as String? ?? Category.autre.value,
      vendeurId: m['vendeurId'] as String? ?? '',
      disponible: m['disponible'] as bool? ?? true,
      dateCreation: _toDate(m['dateCreation']),
    );
  }

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'description': description,
        'prix': prix,
        'imageUrl': imageUrl,
        'categorie': categorie,
        'vendeurId': vendeurId,
        'disponible': disponible,
        'dateCreation': Timestamp.fromDate(dateCreation),
      };

  Product copyWith({
    String? nom,
    String? description,
    double? prix,
    String? imageUrl,
    String? categorie,
    String? vendeurId,
    bool? disponible,
    DateTime? dateCreation,
  }) =>
      Product(
        id: id,
        nom: nom ?? this.nom,
        description: description ?? this.description,
        prix: prix ?? this.prix,
        imageUrl: imageUrl ?? this.imageUrl,
        categorie: categorie ?? this.categorie,
        vendeurId: vendeurId ?? this.vendeurId,
        disponible: disponible ?? this.disponible,
        dateCreation: dateCreation ?? this.dateCreation,
      );

  static DateTime _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
