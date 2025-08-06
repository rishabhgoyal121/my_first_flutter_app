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
  List<Product> products = [];
  bool isLoading = false;
  bool hasMore = true;
  int limit = 10;
  int skip = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadCart();
    _scrollController = ScrollController()..addListener(_onScroll);
    fetchProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<CartProvider>(context, listen: false).setCart(cartData);
        }
      });
      
    }
  }

  Future<void> fetchProducts() async {
    if (isLoading || !hasMore) return;
    if (!mounted) return;
    setState(() => isLoading = true);
    final response = await http.get(
      Uri.parse('https://dummyjson.com/products?limit=$limit&skip=$skip'),
    );
    if (!mounted) return;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> newProducts = data['products'];
      if (!mounted) return;
      setState(() {
        products.addAll(
          newProducts.map((json) => Product.fromJson(json)).toList(),
        );
        skip += limit;
        hasMore = newProducts.length == limit;
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => isLoading = false);
      throw Exception('Failed to load products');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        hasMore) {
      fetchProducts();
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
      body: products.isEmpty && isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount: products.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == products.length) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
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
                    onPressed: () async {
                      final response = await http.put(
                        Uri.parse('https://dummyjson.com/carts/1'),
                        headers: {'content-type': 'application/json'},
                        body: json.encode({
                          'merge': true,
                          'userId': 1,
                          'products': [
                            {'id': product.id, 'quantity': 1},
                          ],
                        }),
                      );

                      if (response.statusCode == 200 ||
                          response.statusCode == 201 ||
                          response.statusCode == 301) {
                        final cartProvider = Provider.of<CartProvider>(
                          context,
                          listen: false,
                        );
                        Provider.of<CartProvider>(
                          context,
                          listen: false,
                        ).addProduct({'quantity': 1, ...product.toJson()});
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
                    icon: Icon(Icons.add_shopping_cart),
                  ),
                );
              },
            ),
    );
  }
}
