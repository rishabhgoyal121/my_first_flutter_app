import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'product.dart';
import 'cart_provider.dart';
import 'add_to_cart_animation.dart';
import 'wishlist_provider.dart';
import 'package:intl/intl.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final GlobalKey cartIconKey = GlobalKey();
  final GlobalKey<AddToCartAnimationState> _animationKey =
      GlobalKey<AddToCartAnimationState>();

  ProductDetailsScreen({super.key, required this.product});

  @override
  State<StatefulWidget> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Product product;

  @override
  void initState() {
    super.initState();
    product = widget.product;
  }

  void _showReviewDialog() {
    int rating = 5;
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Write a Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      rating = index + 1;
                    });
                    Navigator.of(context).pop();
                    _showReviewDialogWithRating(rating, commentController);
                  },
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            TextField(
              controller: commentController,
              decoration: InputDecoration(labelText: 'Comment'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.trim().isEmpty) return;
              final review = Review(
                rating: rating,
                comment: commentController.text.trim(),
                date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                reviewerName: 'Anonymous',
                reviewerEmail: '',
              );
              setState(() {
                product.reviews.add(review);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Review Submitted')));
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialogWithRating(
    int rating,
    TextEditingController commentController,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Write a Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      rating = index + 1;
                    });
                    Navigator.of(context).pop();
                    _showReviewDialogWithRating(rating, commentController);
                  },
                  icon: Icon(index < rating ? Icons.star : Icons.star_border),
                  color: Colors.amber,
                );
              }),
            ),
            TextField(
              controller: commentController,
              decoration: InputDecoration(labelText: 'Comment'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.trim().isEmpty) return;
              final review = Review(
                rating: rating,
                comment: commentController.text.trim(),
                date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                reviewerName: 'Anonymous',
                reviewerEmail: '',
              );
              setState(() {
                product.reviews.add(review);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Review Submitted!')));
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int cartCount = context.watch<CartProvider>().cart['totalQuantity'];
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                key: widget.cartIconKey,
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
                icon: Icon(Icons.shopping_cart),
              ),
              Positioned(
                right: 8,
                top: 4,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.yellowAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$cartCount',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  SizedBox(width: 8),
                  Row(
                    children: [
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.star, size: 14, color: Colors.amberAccent),
                      SizedBox(width: 2),
                      Text(
                        '(${product.reviews.length})',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 10,
                        ),
                      ),
                      Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              context.read<WishlistProvider>().toggleWishlist(
                                product.id,
                              );
                            },
                            icon: Icon(
                              context.watch<WishlistProvider>().isWishlisted(
                                    product.id,
                                  )
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                            color: Colors.pink,
                            tooltip: 'Add to wishlist',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),

              AddToCartAnimation(
                key: widget._animationKey,
                cartIconKey: widget.cartIconKey,
                child: Image.network(product.thumbnail, height: 200),
                onAnimationComplete: () async {},
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  final response = await http.put(
                    Uri.parse('https://dummyjson.com/carts/1'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'merge': true,
                      'userId': 1, // Assuming a user ID of 1 for demo purposes
                      'products': [
                        {'id': product.id, 'quantity': 1},
                      ],
                    }),
                  );
                  Provider.of<CartProvider>(
                    context,
                    listen: false,
                  ).addProduct({'quantity': 1, ...product.toJson()});
                  if (response.statusCode == 200 ||
                      response.statusCode == 201) {
                    final cartProvider = Provider.of<CartProvider>(
                      context,
                      listen: false,
                    );
                    final cartJson = json.encode(cartProvider.cart);
                    if (kIsWeb) {
                      html.window.localStorage['cart'] = cartJson;
                    } else {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('cart', cartJson);
                    }

                    widget._animationKey.currentState?.startAnimation();
                    await Future.delayed(const Duration(milliseconds: 700));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add product to cart')),
                    );
                  }
                },
                child: Text('Add to Cart'),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(
                    '\$${(product.price * (1 - product.discountPercentage / 100)).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(
                    '- ${product.discountPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.blueAccent,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(product.availabilityStatus),
              SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 400;
                  final children = [
                    Icon(Icons.shield),
                    SizedBox(width: 4),
                    Text(
                      product.warrantyInformation,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 24),
                    Icon(Icons.local_shipping),
                    SizedBox(width: 8),
                    Text(
                      product.shippingInformation,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ];
                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: children.sublist(0, 3)),
                        SizedBox(height: 8),
                        Row(children: children.sublist(4)),
                      ],
                    );
                  } else {
                    return Row(children: children);
                  }
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.autorenew),
                  SizedBox(width: 4),
                  Text(product.returnPolicy),
                ],
              ),
              SizedBox(height: 16),
              Text(product.description),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dimensions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Height : ${product.dimensions.height.toStringAsFixed(2)} mm',
                  ),
                  Text(
                    'Width : ${product.dimensions.width.toStringAsFixed(2)} mm',
                  ),
                  Text(
                    'Depth : ${product.dimensions.depth.toStringAsFixed(2)} mm',
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Weight:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${product.weight.toStringAsFixed(2)} lbs',
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),

              if (product.reviews.isEmpty)
                Text('No reviews yet.')
              else
                Column(
                  children: List.generate(product.reviews.length, (index) {
                    final review = product.reviews[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  review.reviewerName,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      review.rating.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              review.comment,
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 6),
                            Text(
                              review.date.substring(0, 10),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _showReviewDialog,
                  label: Text('Write a review'),
                  icon: Icon(Icons.rate_review),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
