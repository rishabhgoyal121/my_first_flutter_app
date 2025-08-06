import 'package:flutter/material.dart';

class OrderProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> get orders => List.unmodifiable(_orders);
  void addOrder(List<dynamic> products, double total, double discountedTotal) {
    _orders.add({
      'products': List.from(products),
      'total': total,
      'discountedTotal': discountedTotal,
      'placedAt': DateTime.now(),
    });
    notifyListeners();
  }
}
