import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'product.dart';
import 'cart_provider.dart';
import 'add_to_cart_animation.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  final GlobalKey cartIconKey = GlobalKey();
  final GlobalKey<AddToCartAnimationState> _animationKey =
      GlobalKey<AddToCartAnimationState>();

  ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    int cartCount = context.watch<CartProvider>().cart['totalQuantity'];
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                key: cartIconKey,
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
                icon: Icon(Icons.shopping_cart),
              ),
              Positioned(
                right: 8,
                top: 4,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.yellowAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$cartCount',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: 8),

            AddToCartAnimation(
              key: _animationKey,
              cartIconKey: cartIconKey,
              child: Image.network(product.thumbnail, height: 200),
              onAnimationComplete: () async {},
            ),
            SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                final response = await http.put(
                  Uri.parse('https://dummyjson.com/carts/1'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'merge': true,
                    'userId': 1, // Assuming a user ID of 1 for demo purposes
                    'products': [
                      {'id': product.id, 'quantity': 1},
                    ],
                  }),
                );
                Provider.of<CartProvider>(
                  context,
                  listen: false,
                ).addProduct({'quantity': 1, ...product.toJson()});
                if (response.statusCode == 200 || response.statusCode == 201) {
                  final cartProvider = Provider.of<CartProvider>(
                    context,
                    listen: false,
                  );
                  final cartJson = json.encode(cartProvider.cart);
                  if (kIsWeb) {
                    html.window.localStorage['cart'] = cartJson;
                  } else {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('cart', cartJson);
                  }

                  _animationKey.currentState?.startAnimation();
                  await Future.delayed(const Duration(milliseconds: 700));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add product to cart')),
                  );
                }
              },
              child: Text('Add to Cart'),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(width: 20),
                Text(
                  '- ${product.discountPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(product.availabilityStatus),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.shield),
                SizedBox(width: 4),
                Text(
                  product.warrantyInformation,
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 24),
                Icon(Icons.local_shipping),
                SizedBox(width: 8),
                Text(
                  product.shippingInformation,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(product.description),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
