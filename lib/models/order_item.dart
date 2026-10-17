class OrderItem {
  final String productId;
  final String nom;
  final double prix;
  final int quantite;
  final double sousTotal;

  const OrderItem({
    required this.productId,
    required this.nom,
    required this.prix,
    required this.quantite,
    required this.sousTotal,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['productId'] as String? ?? '',
        nom: m['nom'] as String? ?? '',
        prix: (m['prix'] as num? ?? 0).toDouble(),
        quantite: (m['quantite'] as num? ?? 1).toInt(),
        sousTotal: (m['sousTotal'] as num? ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'nom': nom,
        'prix': prix,
        'quantite': quantite,
        'sousTotal': sousTotal,
      };
}
