List<Map<String, dynamic>> getOrderTrackingSteps(DateTime placedAt) {
  // Fake tracking steps based on order time
  return [
    {'title': 'Order Placed', 'timestamp': placedAt, 'completed': true},
    {
      'title': 'Order Confirmed',
      'timestamp': placedAt.add(Duration(hours: 2)),
      'completed': true,
    },
    {
      'title': 'Shipped',
      'timestamp': placedAt.add(Duration(hours: 12)),
      'completed': true,
    },
    {
      'title': 'Out for Delivery',
      'timestamp': placedAt.add(Duration(days: 1)),
      'completed': false,
    },
    {
      'title': 'Delivered',
      'timestamp': placedAt.add(Duration(days: 2)),
      'completed': false,
    },
  ];
}
