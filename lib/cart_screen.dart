import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'cart_provider.dart';
import 'order_provider.dart';
import 'order_animation.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isPlacingOrder = false;
  bool _isOrderPlaced = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.cart['products'] as List;
    final orderProvider = Provider.of<OrderProvider>(context);
    // Calculate cart totals
    double cartTotal = 0;
    double cartDiscountedTotal = 0;
    for (var item in cartItems) {
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
          ? Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ListTile(
                        leading: Image.network(item['thumbnail'], width: 50),
                        title: Text(item['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Price: \$ ${item['price']}'),
                            Text('Quantity: ${item['quantity']}'),
                            Text(
                              'Total: \$ ${item['total'].toStringAsFixed(2)}',
                            ),
                            Text(
                              'Discounted Price: \$ ${item['discountedTotal'].toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            final deleteResponse = await http.put(
                              Uri.parse('https://dummyjson.com/carts/1/'),
                              headers: {'Content-Type': 'application/json'},
                              body: json.encode({
                                'merge': true,
                                'userId':
                                    1, // Assuming a user ID of 1 for demo purposes
                                'products': cartItems
                                    .where((i) => i['id'] != item['id'])
                                    .toList(),
                              }),
                            );
                            if (deleteResponse.statusCode == 200 ||
                                deleteResponse.statusCode == 301) {
                              cartProvider.removeProduct(item['id']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Item removed from cart'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to remove item'),
                                ),
                              );
                            }
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
                        'Cart Total: \$ ${cartTotal.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Discounted Total: \$ ${cartDiscountedTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
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
                                        setState(() {
                                          _isPlacingOrder = true;
                                        });
                                        await orderProvider.addOrder(
                                          cartItems,
                                          cartTotal,
                                          cartDiscountedTotal,
                                        );
                                        setState(() {
                                          _isPlacingOrder = false;
                                          _isOrderPlaced = true;
                                        });
                                        await Future.delayed(
                                          Duration(seconds: 2),
                                        );
                                        setState(() {
                                          _isOrderPlaced = false;
                                        });
                                        cartProvider.clearCart();
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
