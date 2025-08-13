import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  final int orderIndex;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.orderIndex,
  });

  @override
  Widget build(BuildContext context) {
    final products = order['products'] as List;
    return Scaffold(
      appBar: AppBar(title: Text('Order #${orderIndex + 1} Details')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Placed at ${order['placedAt'].toString().substring(0, 19)}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('Total: \$${order['total'].toStringAsFixed(2)}'),
            Text(
              'Discounted Total: \$${order['discountedTotal'].toStringAsFixed(2)}',
            ),
            SizedBox(height: 16),
            Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...products.map(
              (p) => ListTile(
                title: Text('${p['title']}'),
                subtitle: Text('Quantity: ${p['quantity']}'),
                trailing: Text('\$${p['price']}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
