import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'order_provider.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;

    return Scaffold(
      appBar: AppBar(title: Text('My orders')),
      body: orders.isEmpty
          ? Center(child: Text('No orders yet.'))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final products = order['products'] as List;
                return Card(
                  margin: EdgeInsets.all(12),
                  child: ListTile(
                    title: Text(
                      'Order #${index + 1} - ${order['placedAt'].toString().substring(0, 19)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: \$${order['total'].toStringAsFixed(2)}'),
                        Text('Discounted: \$${order['discountedTotal'].toStringAsFixed(2)}'),
                        SizedBox(height: 8,),
                        Text('Products:'),
                        ...products.map((p)=>Text('${p['title']} x${p['quantity']} (\$${p['price']})', style: TextStyle(fontSize: 13),))
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
