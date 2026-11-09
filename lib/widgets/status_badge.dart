import 'package:flutter/material.dart';
import '../models/order.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  IconData _iconFor(OrderStatus s) {
    switch (s) {
      case OrderStatus.enAttente:
        return Icons.hourglass_top_outlined;
      case OrderStatus.confirmee:
        return Icons.check_circle_outline;
      case OrderStatus.enPreparation:
        return Icons.soup_kitchen_outlined;
      case OrderStatus.prete:
        return Icons.inventory_2_outlined;
      case OrderStatus.enLivraison:
        return Icons.two_wheeler;
      case OrderStatus.livree:
        return Icons.task_alt;
      case OrderStatus.annulee:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(status), size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
