import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'cart_provider.dart';
import 'order_animation.dart';
import 'cart_item_delete_animation.dart';
import 'package:flutter/services.dart';
import 'product.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isOrderPlaced = false;
  int? _deletingItemId;

  @override
  void initState() {
    super.initState();
  }

  Future<List<Product>> fetchRecommendedProducts(
    List<String> categories,
    List<int> excludeIds,
  ) async {
    List<Product> allRecommendations = [];

    for (String category in categories) {
      try {
        final response = await http.get(
          Uri.parse('https://dummyjson.com/products/category/$category'),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<Product> products = (data['products'] as List)
              .map((p) => Product.fromJson(p))
              .where((p) => !excludeIds.contains(p.id))
              .toList();
          allRecommendations.addAll(products);
        }
      } catch (e) {
        print('Error fetching products for category $category: $e');
      }
    }

    // Remove duplicates and limit to 10 products
    final uniqueProducts = <int, Product>{};
    for (var product in allRecommendations) {
      uniqueProducts[product.id] = product;
    }

    return uniqueProducts.values.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.cart['products'] as List;
    // Calculate cart totals
    double cartTotal = 0;
    double cartDiscountedTotal = 0;
    for (var item in cartItems) {
      // Skip the item being deleted from total calculation
      if (_deletingItemId == item['id']) continue;

      final total = item['total'];
      final discountedTotal = item['discountedTotal'];
      cartTotal += total is num ? total.toDouble() : 0.0;
      cartDiscountedTotal += discountedTotal is num
          ? discountedTotal.toDouble()
          : 0.0;
    }

    return Scaffold(
      appBar: AppBar(title: Text('Cart')),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1601598505513-7489a6272d2a?w=400&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDF8fHxlbnwwfHx8fHw%3D',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.blue[100],
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: Colors.blue[600],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Your cart is empty!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some items to get started',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 0,
                      ),
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        letterSpacing: 0.5,
                      ),
                      elevation: 3,
                      shadowColor: Colors.orangeAccent.withValues(alpha: 0.3),
                    ),
                    child: Text('Start Shopping'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount:
                        cartItems.length + 1, // +1 for recommendations section
                    itemBuilder: (context, index) {
                      // If this is the last item, show recommendations
                      if (index == cartItems.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: FutureBuilder<List<Product>>(
                            future: () {
                              // Get distinct categories from cart items
                              final categories = cartItems
                                  .map((item) => item['category'] as String)
                                  .toSet()
                                  .toList();

                              // Get cart item IDs to exclude
                              final excludeIds = cartItems
                                  .map((item) => item['id'] as int)
                                  .toList();

                              return fetchRecommendedProducts(
                                categories,
                                excludeIds,
                              );
                            }(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return SizedBox();
                              }

                              final recommended = snapshot.data!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'You might also like',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  SizedBox(
                                    height: 200,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: recommended.length,
                                      itemBuilder: (context, idx) {
                                        final product = recommended[idx];
                                        final discountedPrice =
                                            product.price *
                                            (1 -
                                                product.discountPercentage /
                                                    100);

                                        return MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              Navigator.pushNamed(
                                                context,
                                                '/productDetails',
                                                arguments: {
                                                  'product': product.toJson(),
                                                },
                                              );
                                            },
                                            child: Container(
                                              width: 160,
                                              margin: EdgeInsets.only(
                                                right: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Stack(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.vertical(
                                                              top:
                                                                  Radius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                        child: Image.network(
                                                          product.thumbnail,
                                                          height: 120,
                                                          width:
                                                              double.infinity,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) {
                                                                return Container(
                                                                  height: 120,
                                                                  color: Colors
                                                                      .grey[200],
                                                                  child: Icon(
                                                                    Icons
                                                                        .image_not_supported,
                                                                  ),
                                                                );
                                                              },
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                product.title,
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                              Spacer(),
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    '\$${discountedPrice.toStringAsFixed(2)}',
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .green,
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  if (product
                                                                          .discountPercentage >
                                                                      0)
                                                                    Text(
                                                                      '\$${product.price.toStringAsFixed(2)}',
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            10,
                                                                        decoration:
                                                                            TextDecoration.lineThrough,
                                                                        color: Colors
                                                                            .grey,
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  // Add to cart button positioned at bottom right
                                                  Positioned(
                                                    bottom: 8,
                                                    right: 8,
                                                    child: GestureDetector(
                                                      onTap: () async {
                                                        HapticFeedback.lightImpact();
                                                        try {
                                                          // Add to cart API call
                                                          await http.put(
                                                            Uri.parse(
                                                              'https://dummyjson.com/carts/1',
                                                            ),
                                                            headers: {
                                                              'Content-Type':
                                                                  'application/json',
                                                            },
                                                            body: json.encode({
                                                              'merge': true,
                                                              'userId': 1,
                                                              'products': [
                                                                {
                                                                  'id': product
                                                                      .id,
                                                                  'quantity': 1,
                                                                },
                                                              ],
                                                            }),
                                                          );

                                                          // Add to local cart
                                                          final cartProvider =
                                                              Provider.of<
                                                                CartProvider
                                                              >(
                                                                context,
                                                                listen: false,
                                                              );
                                                          cartProvider
                                                              .addProduct({
                                                                'quantity': 1,
                                                                ...product
                                                                    .toJson(),
                                                              });

                                                          // Show success message
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '${product.title} added to cart!',
                                                              ),
                                                              duration: Duration(
                                                                milliseconds:
                                                                    1500,
                                                              ),
                                                              backgroundColor:
                                                                  Colors.green,
                                                            ),
                                                          );
                                                        } catch (e) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Failed to add to cart',
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                          7,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .deepPurpleAccent,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  ),
                                                              blurRadius: 4,
                                                              offset: Offset(
                                                                0,
                                                                2,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .add_shopping_cart,
                                                          size: 19,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      }

                      // Otherwise, show cart item
                      final item = cartItems[index];
                      final isDeleting = _deletingItemId == item['id'];
                      return CartItemDeleteAnimation(
                        key: ValueKey(item['id']),
                        isDeleting: isDeleting,
                        onAnimationEnd: isDeleting
                            ? () async {
                                try {
                                  final currentCartItems =
                                      List<Map<String, dynamic>>.from(
                                        cartItems,
                                      );
                                  final remainingProducts = currentCartItems
                                      .where(
                                        (item) => item['id'] != _deletingItemId,
                                      )
                                      .map(
                                        (item) => {
                                          'id': item['id'],
                                          'quantity': item['quantity'],
                                        },
                                      )
                                      .toList();

                                  // Make API call first
                                  final deleteResponse = await http.put(
                                    Uri.parse('https://dummyjson.com/carts/1'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: json.encode({
                                      'merge':
                                          false, // Use false to replace entire cart
                                      'userId': 1,
                                      'products': remainingProducts,
                                    }),
                                  );
                                  cartProvider.removeProduct(_deletingItemId!);
                                  if (!mounted) return;
                                  setState(() {
                                    _deletingItemId = null;
                                  });
                                  if (deleteResponse.statusCode != 200 &&
                                      deleteResponse.statusCode != 301) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Item removed locally, but failed to sync with server',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  cartProvider.removeProduct(_deletingItemId!);
                                  if (!mounted) return;
                                  setState(() {
                                    _deletingItemId = null;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Item removed locally, but network error occurred',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            : null,
                        child: ListTile(
                          leading: Image.network(item['thumbnail'], width: 50),
                          title: Text(item['title']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Discounted Price: \$ ${(item['price'] * (1 - item['discountPercentage'] / 100)).toStringAsFixed(2)}',
                              ),
                              Row(
                                children: [
                                  Text('Quantity: '),
                                  IconButton(
                                    onPressed:
                                        isDeleting || (item['quantity'] < 2)
                                        ? null
                                        : () {
                                            HapticFeedback.lightImpact();
                                            cartProvider.addProduct({
                                              ...item,
                                              'quantity': -1,
                                            });
                                          },
                                    icon: Icon(Icons.remove, size: 14),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    item['quantity'].toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  IconButton(
                                    onPressed: isDeleting
                                        ? null
                                        : () {
                                            HapticFeedback.lightImpact();
                                            cartProvider.addProduct({
                                              ...item,
                                              'quantity': 1,
                                            });
                                          },
                                    icon: Icon(Icons.add, size: 14),
                                  ),
                                ],
                              ),
                              Text(
                                'Total: \$ ${item['discountedTotal'].toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: isDeleting
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    if (!mounted) return;
                                    setState(() {
                                      _deletingItemId = item['id'];
                                    });
                                  },
                          ),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushNamed(
                              context,
                              '/productDetails',
                              arguments: {'product': item},
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(),
                      Text(
                        '  Total: \$ ${cartDiscountedTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 600),
                        child: _isOrderPlaced
                            ? Container(
                                height: 48,
                                alignment: Alignment.center,
                                child: OrderAnimation(
                                  isLoading: false,
                                  isSuccess: true,
                                  key: ValueKey('success'),
                                ),
                              )
                            : _isPlacingOrder
                            ? Container(
                                height: 48,
                                alignment: Alignment.center,
                                child: OrderAnimation(
                                  isLoading: true,
                                  isSuccess: false,
                                  key: ValueKey('loading'),
                                ),
                              )
                            : ElevatedButton(
                                key: ValueKey('button'),
                                onPressed: cartItems.isEmpty || _isPlacingOrder
                                    ? null
                                    : () async {
                                        HapticFeedback.lightImpact();
                                        // Navigate to checkout screen
                                        Navigator.pushNamed(
                                          context,
                                          '/checkout',
                                          arguments: {
                                            'cartItems': cartItems,
                                            'cartTotal': cartTotal,
                                            'cartDiscountedTotal':
                                                cartDiscountedTotal,
                                          },
                                        );
                                      },
                                child: Text('Checkout'),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
