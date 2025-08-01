import 'package:flutter/material.dart';
import 'product.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.title),),
      body: Padding(padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(product.thumbnail, height: 200,),
            ),
            SizedBox(height: 16,),
            Text(product.title, style: Theme.of(context).textTheme.headlineLarge,),
            SizedBox(height: 8),
            Text('\$${product.price.toStringAsFixed(2)}'),
            SizedBox(height: 16),
            Text(product.description)
          ],
        ),
      ),
    );
  }
}
