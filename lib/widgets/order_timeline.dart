import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderTimeline extends StatelessWidget {
  final OrderStatus current;
  const OrderTimeline({super.key, required this.current});

  static const _steps = [
    OrderStatus.enAttente,
    OrderStatus.confirmee,
    OrderStatus.enPreparation,
    OrderStatus.prete,
    OrderStatus.enLivraison,
    OrderStatus.livree,
  ];

  @override
  Widget build(BuildContext context) {
    if (current == OrderStatus.annulee) {
      return ListTile(
        leading: Icon(Icons.cancel, color: OrderStatus.annulee.color),
        title: Text(OrderStatus.annulee.label,
            style: TextStyle(color: OrderStatus.annulee.color, fontWeight: FontWeight.bold)),
        subtitle: const Text('Cette commande a été annulée'),
      );
    }
    final idx = _steps.indexOf(current);
    return Column(
      children: List.generate(_steps.length, (i) {
        final s = _steps[i];
        final done = i <= idx;
        final isCurrent = i == idx;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: done ? s.color : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(done ? Icons.check : Icons.circle,
                    size: 16, color: done ? Colors.white : Colors.grey),
              ),
              if (i < _steps.length - 1)
                Container(width: 2, height: 24, color: i < idx ? s.color : Colors.grey.shade300),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 20),
                child: Text(s.label,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: done ? s.color : Colors.grey,
                    )),
              ),
            ),
          ],
        );
      }),
    );
  }
}
