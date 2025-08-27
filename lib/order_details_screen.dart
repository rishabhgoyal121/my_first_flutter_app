import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_first_flutter_app/product.dart';
import 'product_details_screen.dart';
import 'package:flutter/services.dart';
import 'order_tracking_helper.dart';

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
    final trackingSteps = getOrderTrackingSteps(placedAt);
    final latestStep = trackingSteps.lastWhere(
      (step) => step['completed'],
      orElse: () => trackingSteps.first,
    );
    final String formattedDate = DateFormat(
      'MMM dd, yyyy \'at\' hh:mm a',
    ).format(placedAt);
    return Scaffold(
      appBar: AppBar(title: Text('Order #${orderIndex + 1} Details')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 4,
              runSpacing: 4,
              children: [
                Text('Order Tracking:'),
                Text(
                  '${latestStep['title']}, ',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'delivery by  ${DateFormat('MMM dd, hh:mm a').format(trackingSteps[trackingSteps.length - 1]['timestamp'])}',
                ),
              ],
            ),
            SizedBox(height: 8),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        OrderTrackingModal(trackingSteps: trackingSteps),
                  );
                },
                child: Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: OrderTrackingBar(trackingSteps: trackingSteps),
                  ),
                ),
              ),
            ),
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

class OrderTrackingBar extends StatelessWidget {
  final List<Map<String, dynamic>> trackingSteps;
  const OrderTrackingBar({required this.trackingSteps, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(trackingSteps.length, (i) {
        final step = trackingSteps[i];
        final isLast = i == trackingSteps.length - 1;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: step['completed'] ? Colors.green : Colors.grey,
                child: Icon(
                  step['completed'] ? Icons.check : Icons.circle,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 4,
                    color: trackingSteps[i + 1]['completed']
                        ? Colors.green
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class OrderTrackingModal extends StatelessWidget {
  final List<Map<String, dynamic>> trackingSteps;
  const OrderTrackingModal({required this.trackingSteps, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Order Tracking')),
        body: ListView.builder(
          padding: EdgeInsets.all(24),
          itemCount: trackingSteps.length,
          itemBuilder: (context, i) {
            final step = trackingSteps[i];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: step['completed']
                          ? Colors.green
                          : Colors.grey,
                      child: Icon(
                        step['completed'] ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (i != trackingSteps.length - 1)
                      Container(
                        width: 4,
                        height: 40,
                        color: trackingSteps[i + 1]['completed']
                            ? Colors.green
                            : Colors.grey[300],
                      ),
                  ],
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: step['completed'] ? Colors.green : Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Wrap(
                        alignment: WrapAlignment.start,
                        children: [
                          if (!step['completed'])
                            Text(
                              'expected by ',
                              style: TextStyle(fontSize: 12),
                            ),
                          Text(
                            DateFormat(
                              'MMM dd, hh:mm a',
                            ).format(step['timestamp']),
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
