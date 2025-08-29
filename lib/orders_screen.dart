import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/product.dart';
import 'package:my_first_flutter_app/product_details_screen.dart';
import 'package:provider/provider.dart';
import 'order_provider.dart';
import 'order_details_screen.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'order_tracking_helper.dart';
import 'src/widgets/safe_network_image.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text('My orders')),
      body: orders.isEmpty
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
                      child: SafeNetworkImage(
                        imageUrl:
                            'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400&h=400&fit=crop&crop=center',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No orders yet!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start shopping to see your orders here',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
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
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final products = order['products'] as List;
                final DateTime placedAt = DateTime.parse(
                  order['placedAt'] as String,
                );
                final trackingSteps = getOrderTrackingSteps(placedAt);
                final latestStep = trackingSteps.lastWhere(
                  (step) => step['completed'],
                  orElse: () => trackingSteps.first,
                );
                final String formattedDate = DateFormat(
                  'MMM dd, yyyy \'at\' hh:mm a',
                ).format(placedAt);
                return Card(
                  margin: EdgeInsets.all(12),
                  child: ListTile(
                    title: Text(
                      'Order #${orders.length - index}, placed on $formattedDate',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: \$${order['total'].toStringAsFixed(2)}'),
                        Text(
                          'Discounted: \$${order['discountedTotal'].toStringAsFixed(2)}',
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tracking: ${latestStep['title']}',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text('Products:'),
                        SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: products.length,
                            itemBuilder: (context, idx) {
                              final p = products[idx];
                              return InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailsScreen(
                                        product: Product.fromJson(p),
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  child: SizedBox(
                                    width: 80,
                                    child: Stack(
                                      children: [
                                        Column(
                                          children: [
                                            Expanded(
                                              child: SafeNetworkImage(
                                                imageUrl: p['thumbnail'] ?? '',
                                                fit: BoxFit.cover,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Text(
                                                p['title'],
                                                style: TextStyle(fontSize: 10),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            padding: EdgeInsets.all(2),
                                            color: Colors.black.withValues(
                                              alpha: 0.7,
                                            ),
                                            child: Text(
                                              'x${p['quantity']}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
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
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(
                            order: order,
                            orderIndex: index,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
