import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_first_flutter_app/product.dart';
import 'product_details_screen.dart';
import 'package:flutter/services.dart';

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
    final DateTime placedAt = DateTime.parse(order['placedAt'] as String);
    final String formattedDate = DateFormat(
      'MMM dd, yyyy \'at\' hh:mm a',
    ).format(placedAt);
    return Scaffold(
      appBar: AppBar(title: Text('Order #${orderIndex + 1} Details')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Placed at $formattedDate', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Total: \$${order['total'].toStringAsFixed(2)}'),
            Text(
              'Discounted Total: \$${order['discountedTotal'].toStringAsFixed(2)}',
            ),
            SizedBox(height: 16),
            Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...products.map(
              (p) => ListTile(
                leading: p['thumbnail'] != null
                    ? Image.network(
                        p['thumbnail'],
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.broken_image),
                      )
                    : Icon(Icons.image_not_supported),
                title: Text('${p['title']}'),
                subtitle: Text('Quantity: ${p['quantity']}'),
                trailing: Text('\$${p['price']}'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailsScreen(product: Product.fromJson(p)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
