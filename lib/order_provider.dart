import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class OrderProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _orders = [];

  List<Map<String, dynamic>> get orders => List.unmodifiable(_orders);

  OrderProvider() {
    _loadOrders();
  }

  Future<void> addOrder(
    List<dynamic> products,
    double total,
    double discountedTotal,
  ) async {
    _orders.add({
      'products': List.from(products),
      'total': total,
      'discountedTotal': discountedTotal,
      'placedAt': DateTime.now().toIso8601String(),
    });
    await _saveOrders();
    notifyListeners();
  }

  Future<void> _saveOrders() async {
    final ordersJson = jsonEncode(_orders);
    if (kIsWeb) {
      html.window.localStorage['orders'] = ordersJson;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('orders', ordersJson);
    }
  }

  Future<void> _loadOrders() async {
    String? ordersJson;
    if (kIsWeb) {
      ordersJson = html.window.localStorage['orders'];
    } else {
      final prefs = await SharedPreferences.getInstance();
      ordersJson = prefs.getString('orders');
    }

    if (ordersJson != null) {
      final List<dynamic> decoded = jsonDecode(ordersJson);
      _orders.clear();
      _orders.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
      notifyListeners();
    }
  }
}
