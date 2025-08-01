import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    final response = await http.get(Uri.parse('https://dummyjson.com/carts/1'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        cartItems = data['products'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate cart totals
    double cartTotal = 0;
    double cartDiscountedTotal = 0;
    for (var item in cartItems) {
      cartTotal += (item['total'] ?? 0).toDouble();
      cartDiscountedTotal += (item['discountedTotal'] ?? 0).toDouble();
    }

    return Scaffold(
      appBar: AppBar(title: Text('Cart')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
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
                            Text('Quantity: ${item['quantity']}'),
                            Text('Price: \$ ${item['price']}'),
                            Text(
                              'Total: \$ ${(item['total'] as num).toStringAsFixed(2)}',
                            ),
                            Text(
                              'Discounted Price: \$ ${(item['discountedTotal'] as num).toStringAsFixed(2)}',
                            ),
                          ],
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
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
