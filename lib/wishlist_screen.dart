import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'wishlist_provider.dart';
import 'product.dart';
import 'product_details_screen.dart';
import 'package:flutter/services.dart';
import 'src/widgets/safe_network_image.dart';

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
        body: Center(
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
                        'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400&h=400&fit=crop&crop=center',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Your wishlist is empty!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Start exploring and save items you love',
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/');
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
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
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Wishlist')),
      body: ListView.builder(
        itemCount: wishlistedProducts.length,
        itemBuilder: (context, index) {
          final product = wishlistedProducts[index];
          return ListTile(
            leading: SafeNetworkImage(
              imageUrl: product.thumbnail,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(8),
            ),
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
