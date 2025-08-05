import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'product.dart';
import 'product_details_screen.dart';
import 'cart_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> productsFuture;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadCart();
    productsFuture = fetchProducts();
  }

  Future<void> _checkAuth() async {
    if (kIsWeb) {
      final cookies = html.document.cookie?.split('; ') ?? [];
      final accessTokenCookie = cookies.firstWhere(
        (cookie) => cookie.startsWith('accessToken='),
        orElse: () => '',
      );
      if (accessTokenCookie.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null || token.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
    }
  }

  Future<void> _loadCart() async {
    String? cartJson;
    if (kIsWeb) {
      cartJson = html.window.localStorage['cart'];
    } else {
      final prefs = await SharedPreferences.getInstance();
      cartJson = prefs.getString('cart');
    }
    if (cartJson != null && cartJson.isNotEmpty) {
      final cartData = json.decode(cartJson);
      Provider.of<CartProvider>(context, listen: false).setCart(cartData);
    }
  }

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(
      Uri.parse('https://dummyjson.com/products'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['products'];
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  @override
  Widget build(BuildContext context) {
    int cartCount = context.watch<CartProvider>().cart['totalQuantity'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
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
      body: FutureBuilder(
        future: productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('no products found.'));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: Image.network(product.thumbnail),
                title: Text(product.title),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailsScreen(product: product),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: Icon(Icons.add_shopping_cart),
                  onPressed: () async {
                    final response = await http.put(
                      Uri.parse('https://dummyjson.com/carts/1'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({
                        'merge': true,
                        'userId':
                            1, // Assuming a user ID of 1 for demo purposes
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Product added to cart')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add product to cart'),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
