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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  SizedBox(width: 8),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: TextStyle(color: Colors.amberAccent, fontSize: 16),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.star, size: 14, color: Colors.amberAccent),
                  SizedBox(width: 2),
                  Text(
                    '(${product.reviews.length})',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 10),
                  ),
                ],
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
                  if (response.statusCode == 200 ||
                      response.statusCode == 201) {
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
              Row(
                children: [
                  Icon(Icons.autorenew),
                  SizedBox(width: 4),
                  Text(product.returnPolicy),
                ],
              ),
              SizedBox(height: 16),
              Text(product.description),
              SizedBox(height: 16),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    'Dimensions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 16),
                  Text('Height : '),
                  Text(product.dimensions.height.toStringAsFixed(2)),
                  SizedBox(width: 16),
                  Text('Width : '),
                  Text(product.dimensions.width.toStringAsFixed(2)),
                  SizedBox(width: 16),
                  Text('Depth : '),
                  Text(product.dimensions.depth.toStringAsFixed(2)),
                  SizedBox(width: 16),
                  Text(
                    '(in mm)',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Weight:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 16),
                  Text(product.weight.toStringAsFixed(2)),
                  SizedBox(width: 16),
                  Text(
                    '(in lbs)',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),

              if (product.reviews.isEmpty)
                Text('No reviews yet.')
              else
                Column(
                  children: List.generate(product.reviews.length, (index) {
                    final review = product.reviews[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  review.reviewerName,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      review.rating.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              review.comment,
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 6),
                            Text(
                              review.date.substring(0, 10),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
