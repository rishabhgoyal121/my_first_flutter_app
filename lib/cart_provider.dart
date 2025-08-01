import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<dynamic> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => List.unmodifiable(_cartItems);

  void addItem(Map<String, dynamic> item) {
    final index = _cartItems.indexWhere((i) => i['id'] == item['id']);
    if (index >= 0) {
      _cartItems[index]['quantity'] += item['quantity'];
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  void removeItem(int id) {
    _cartItems.removeWhere((i) => i['id'] == id);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
