import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String fmtPrice(double v) => '${v.toStringAsFixed(2)} TND';
String fmtDate(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);

void showSnack(BuildContext ctx, String msg, {bool error = false}) {
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade600 : null,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

String mapsUrl(String adresse) =>
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(adresse)}';
