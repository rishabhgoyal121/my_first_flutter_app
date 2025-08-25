import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'wishlist_provider.dart';
import 'product.dart';
import 'product_details_screen.dart';
import 'package:flutter/services.dart';

class WishlistScreen extends StatelessWidget {
  final List<Product> allProducts;

  const WishlistScreen({super.key, required this.allProducts});

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = context.watch<WishlistProvider>();
    final wishlistedIds = wishlistProvider.wishlist;
    final wishlistedProducts = allProducts
        .where((product) => wishlistedIds.contains(product.id))
        .toList();
    if (wishlistedProducts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Wishlist')),
        body: Center(child: Text('No items in wishlist')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Wishlist')),
      body: ListView.builder(
        itemCount: wishlistedProducts.length,
        itemBuilder: (context, index) {
          final product = wishlistedProducts[index];
          return ListTile(
            leading: Image.network(product.thumbnail, width: 56, height: 56),
            title: Text(product.title),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            trailing: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                wishlistProvider.toggleWishlist(product.id);
              },
              icon: Icon(Icons.delete, color: Colors.red),
              tooltip: 'Remove from wishlist',
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
