import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';

class CartProvider extends ChangeNotifier {
  final Map<String, dynamic> _cart = {
    'id': 1,
    "products": [],
    'total': 0.0,
    'discountedTotal': 0.0,
    'userId': 1,
    'totalProducts': 0,
    'totalQuantity': 0,
  };

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  CartProvider() {
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    await _loadCartFromLocalStorage();
    _isInitialized = true;
    notifyListeners();
  }

  Map<String, dynamic> get cart => Map.unmodifiable(_cart);

  void setUserId(int userId) {
    _cart['userId'] = userId;
    notifyListeners();
  }

  void addProduct(Map<String, dynamic> product) {
    final products = _cart['products'] as List;
    final index = products.indexWhere((p) => p['id'] == product['id']);
    if (index >= 0) {
      products[index]['quantity'] += product['quantity'];
      products[index]['total'] =
          products[index]['price'] * products[index]['quantity'];
      products[index]['discountedTotal'] =
          products[index]['total'] *
          (1 - (products[index]['discountPercentage'] ?? 0) / 100);
    } else {
      product['total'] = product['price'] * product['quantity'];
      product['discountedTotal'] =
          product['total'] * (1 - (product['discountPercentage'] ?? 0) / 100);
      products.add(product);
    }
    _recalculateTotals();
    notifyListeners();
    _saveCartToLocalStorage();
  }

  void removeProduct(int productId) {
    final products = _cart['products'] as List;
    products.removeWhere((p) => p['id'] == productId);
    _recalculateTotals();
    notifyListeners();
    _saveCartToLocalStorage();
  }

  void clearCart() async {
    _cart['products'].clear();
    _recalculateTotals();
    notifyListeners();
    if (kIsWeb) {
      html.window.localStorage.remove('cart');
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart');
    }
  }

  void setCart(Map<String, dynamic> cart) {
    _cart.clear();
    _cart.addAll(cart);
    notifyListeners();
    _saveCartToLocalStorage();
  }

  void _recalculateTotals() {
    final products = _cart["products"] as List;
    _cart["totalProducts"] = products.length;
    _cart["totalQuantity"] = products.fold(
      0,
      (sum, p) => sum + ((p["quantity"] ?? 0) as int),
    );
    _cart["total"] = products.fold(0.0, (sum, p) => sum + (p["total"] ?? 0.0));
    _cart["discountedTotal"] = products.fold(
      0.0,
      (sum, p) => sum + (p["discountedTotal"] ?? 0.0),
    );
  }

  Future<void> _loadCartFromLocalStorage() async {
    try {
      String? cartJson;
      if (kIsWeb) {
        cartJson = html.window.localStorage['cart'];
      } else {
        final prefs = await SharedPreferences.getInstance();
        cartJson = prefs.getString('cart');
      }

      if (cartJson != null) {
        final Map<String, dynamic> savedCart = json.decode(cartJson);
        _cart.clear();
        _cart.addAll(savedCart);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart from local storage: $e');
    }
  }

  Future<void> _saveCartToLocalStorage() async {
    final cartJson = json.encode(_cart);
    if (kIsWeb) {
      html.window.localStorage['cart'] = cartJson;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cart', cartJson);
    }
  }
}
