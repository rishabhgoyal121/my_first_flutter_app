import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
            Text(product.description),
            SizedBox(height: 16),
            ElevatedButton(onPressed: () async{
              final response = await http.post(
                Uri.parse('https://dummyjson.com/carts/add'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'userId': 1, // Assuming a user ID of 1 for demo purposes
                  'products': [
                    {
                      'id': product.id,
                      'quantity': 1,
                    }
                  ],
                }),
              );
              if (response.statusCode == 200 || response.statusCode == 201) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Product added to cart')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add product to cart')),
                );
              }
            }, child: Text('Add to Cart'))
          ],
        ),
      ),
    );
  }
}
