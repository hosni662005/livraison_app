import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'order_item.dart';

/// Cycle : enAttente → confirmee → enPreparation → prete → enLivraison → livree
///                    ↘ annulee (depuis enAttente/confirmee)
enum OrderStatus {
  enAttente('enAttente', 'En attente', Color(0xFFFF9800)),
  confirmee('confirmee', 'Confirmée', Color(0xFF2196F3)),
  enPreparation('enPreparation', 'En préparation', Color(0xFF9C27B0)),
  prete('prete', 'Prête', Color(0xFF00BCD4)),
  enLivraison('enLivraison', 'En livraison', Color(0xFF4CAF50)),
  livree('livree', 'Livrée', Color(0xFF2E7D32)),
  annulee('annulee', 'Annulée', Color(0xFFF44336));

  const OrderStatus(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static OrderStatus fromString(String v) =>
      OrderStatus.values.firstWhere((e) => e.value == v, orElse: () => OrderStatus.enAttente);

  bool get isTerminal => this == livree || this == annulee;
}

class Order {
  final String id;
  final String clientId;
  final String? vendeurId;
  final String? livreurId;
  final List<OrderItem> items;
  final double total;
  final OrderStatus statut;
  final String adresseLivraison;
  final String telephone;
  final String? note;
  final DateTime dateCreation;
  final DateTime dateMiseAJour;

  const Order({
    required this.id,
    required this.clientId,
    this.vendeurId,
    this.livreurId,
    required this.items,
    required this.total,
    required this.statut,
    required this.adresseLivraison,
    required this.telephone,
    this.note,
    required this.dateCreation,
    required this.dateMiseAJour,
  });

  /// RG-03 — annulation seulement depuis enAttente ou confirmee
  bool canBeCancelled() =>
      statut == OrderStatus.enAttente || statut == OrderStatus.confirmee;

  /// RG-06 — transition séquentielle stricte
  OrderStatus? nextStatus() {
    switch (statut) {
      case OrderStatus.enAttente:
        return OrderStatus.confirmee;
      case OrderStatus.confirmee:
        return OrderStatus.enPreparation;
      case OrderStatus.enPreparation:
        return OrderStatus.prete;
      case OrderStatus.prete:
        return OrderStatus.enLivraison;
      case OrderStatus.enLivraison:
        return OrderStatus.livree;
      case OrderStatus.livree:
      case OrderStatus.annulee:
        return null;
    }
  }

  factory Order.fromMap(String id, Map<String, dynamic> m) => Order(
        id: id,
        clientId: m['clientId'] as String? ?? '',
        vendeurId: m['vendeurId'] as String?,
        livreurId: m['livreurId'] as String?,
        items: (m['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        total: (m['total'] as num? ?? 0).toDouble(),
        statut: OrderStatus.fromString(m['statut'] as String? ?? 'enAttente'),
        adresseLivraison: m['adresseLivraison'] as String? ?? '',
        telephone: m['telephone'] as String? ?? '',
        note: m['note'] as String?,
        dateCreation: _toDate(m['dateCreation']),
        dateMiseAJour: _toDate(m['dateMiseAJour']),
      );

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'vendeurId': vendeurId,
        'livreurId': livreurId,
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'statut': statut.value,
        'adresseLivraison': adresseLivraison,
        'telephone': telephone,
        'note': note,
        'dateCreation': Timestamp.fromDate(dateCreation),
        'dateMiseAJour': Timestamp.fromDate(dateMiseAJour),
      };

  Order copyWith({
    String? vendeurId,
    String? livreurId,
    OrderStatus? statut,
    DateTime? dateMiseAJour,
  }) =>
      Order(
        id: id,
        clientId: clientId,
        vendeurId: vendeurId ?? this.vendeurId,
        livreurId: livreurId ?? this.livreurId,
        items: items,
        total: total,
        statut: statut ?? this.statut,
        adresseLivraison: adresseLivraison,
        telephone: telephone,
        note: note,
        dateCreation: dateCreation,
        dateMiseAJour: dateMiseAJour ?? this.dateMiseAJour,
      );

  static DateTime _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
