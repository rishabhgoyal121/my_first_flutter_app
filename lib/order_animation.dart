import 'package:flutter/material.dart';

class OrderAnimation extends StatelessWidget {
  final bool isLoading;
  final bool isSuccess;

  const OrderAnimation({
    super.key,
    required this.isLoading,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {

    if (isSuccess) {
      return Icon(Icons.check_circle, color: Colors.green, size: 48);
    }
    if (isLoading) {
      return SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2),
      );
    }

    return const SizedBox.shrink();
  }
}
