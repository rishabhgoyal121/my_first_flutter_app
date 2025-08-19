import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'dart:convert';

class WishlistProvider extends ChangeNotifier {
  List<int> _wishlist = [];

  List<int> get wishlist => _wishlist;

  WishlistProvider() {
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    String? data;
    if (kIsWeb) {
      data = html.window.localStorage['wishlist'];
    } else {
      final prefs = await SharedPreferences.getInstance();
      data = prefs.getString('wishlist');
    }
    if (data != null) {
      _wishlist = List<int>.from(json.decode(data));
      notifyListeners();
    }
  }

  Future<void> toggleWishlist(int productId) async {
    if (isWishlisted(productId)) {
      _wishlist.remove(productId);
    } else {
      _wishlist.add(productId);
    }
    await saveWishlist();
    notifyListeners();
  }

  bool isWishlisted(int productId) => _wishlist.contains(productId);

  Future<void> saveWishlist() async {
    final data = json.encode(_wishlist);
    if (kIsWeb) {
      html.window.localStorage['wishlist'] = data;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wishlist', data);
    }
  }
}
