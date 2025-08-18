import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_first_flutter_app/add_to_cart_animation_small.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'product.dart';
import 'product_details_screen.dart';
import 'cart_provider.dart';
import 'wishlist_provider.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum SortOption {
  ratingDesc,
  ratingAsc,
  priceAsc,
  priceDesc,
  discountDesc,
  discountAsc,
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  List<Product> allProducts = [];
  bool isLoading = false;
  bool hasMore = true;
  int limit = 10;
  int skip = 0;
  late ScrollController _scrollController;
  Timer? _debounce;

  final double _minPrice = 0;
  final double _maxPrice = 1000;
  double _selectedMinPrice = 0;
  double _selectedMaxPrice = 1000;
  double _selectedMinRating = 0;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategorySlug;

  final GlobalKey cartIconKey = GlobalKey();
  List<GlobalKey<AddToCartAnimationState>> animationKeys = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  SortOption? _selectedSort;

  Map<String, String> _getSortParams(SortOption? sort) {
    switch (sort) {
      case SortOption.ratingAsc:
        return {'sortBy': 'rating', 'order': 'asc'};
      case SortOption.ratingDesc:
        return {'sortBy': 'rating', 'order': 'desc'};
      case SortOption.priceAsc:
        return {'sortBy': 'price', 'order': 'asc'};
      case SortOption.priceDesc:
        return {'sortBy': 'price', 'order': 'desc'};
      case SortOption.discountAsc:
        return {'sortBy': 'discountPercentage', 'order': 'asc'};
      case SortOption.discountDesc:
        return {'sortBy': 'discountPercentage', 'order': 'desc'};
      default:
        return {};
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAuth();
    // _loadCart();
    _scrollController = ScrollController()..addListener(_onScroll);
    fetchProducts();
    fetchCategories();
    animationKeys = List.generate(
      100,
      (_) => GlobalKey<AddToCartAnimationState>(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      searchProducts(query);
    });
  }

  Future<void> _checkAuth() async {
    if (kIsWeb) {
      final cookies = html.document.cookie?.split('; ') ?? [];
      final accessTokenCookie = cookies.firstWhere(
        (cookie) => cookie.startsWith('accessToken='),
        orElse: () => '',
      );
      if (accessTokenCookie.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null || token.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
    }
  }

  Future<void> fetchProducts() async {
    if (isLoading || !hasMore) return;
    if (!mounted) return;
    setState(() => isLoading = true);

    final sortParams = _getSortParams(_selectedSort);
    final sortQuery = sortParams.isNotEmpty
        ? '&sortBy=${sortParams['sortBy']}&order=${sortParams['order']}'
        : '';

    final response = await http.get(
      Uri.parse('https://dummyjson.com/products?limit=1000$sortQuery'),
    );
    if (!mounted) return;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> newProducts = data['products'];
      if (!mounted) return;
      setState(() {
        allProducts = newProducts
            .map((json) => Product.fromJson(json))
            .toList();
      });
      applyFilters();
    } else {
      if (!mounted) return;
      setState(() => isLoading = false);
      throw Exception('Failed to load products');
    }
  }

  void applyFilters() {
    List<Product> filtered = allProducts.where((product) {
      final matchesCategory =
          _selectedCategorySlug == null ||
          product.category == _selectedCategorySlug;
      final matchesPrice =
          product.price >= _selectedMinPrice &&
          product.price <= _selectedMaxPrice;
      final matchesRating = product.rating >= _selectedMinRating;
      return matchesCategory && matchesPrice && matchesRating;
    }).toList();
    setState(() {
      products = filtered;
      isLoading = false;
      hasMore = false;
    });
  }

  Future<void> fetchCategories() async {
    final response = await http.get(
      Uri.parse('https://dummyjson.com/products/categories'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> cats = json.decode(response.body);
      setState(() {
        _categories = cats.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        products.clear();
        skip = 0;
        hasMore = true;
      });
      fetchProducts();
      return;
    }
    if (!mounted) return;
    setState(() {
      isLoading = true;
      _isSearching = true;
    });
    final response = await http.get(
      Uri.parse('https://dummyjson.com/products/search?q=$query'),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 301) {
      final data = json.decode(response.body);
      final List<dynamic> newProducts = data['products'];
      if (!mounted) return;
      setState(() {
        products = newProducts.map((json) => Product.fromJson(json)).toList();
        isLoading = false;
        hasMore = false;
      });
    } else {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('failed to search products')));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        hasMore) {
      fetchProducts();
    }
  }

  void _onSortSelected(SortOption? option) {
    if (!mounted) return;
    setState(() {
      _selectedSort = option;
      products.clear();
      skip = 0;
      hasMore = true;
    });
    fetchProducts();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.all(16),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text('Category'),
                  DropdownButton<String>(
                    value: _selectedCategorySlug,
                    hint: Text('Select category'),
                    isExpanded: true,
                    items: _categories
                        .map(
                          (cat) => DropdownMenuItem<String>(
                            value: cat['slug'],
                            child: Text(cat['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setModalState(() => _selectedCategorySlug = val);
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Price Range (\$${_selectedMinPrice.toInt()} - \$${_selectedMaxPrice.toInt()})',
                  ),
                  RangeSlider(
                    min: _minPrice,
                    max: _maxPrice,
                    divisions: 20,
                    values: RangeValues(_selectedMinPrice, _selectedMaxPrice),
                    onChanged: (values) {
                      setModalState(() {
                        _selectedMinPrice = values.start;
                        _selectedMaxPrice = values.end;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Minimum Rating (${_selectedMinRating.toStringAsFixed(1)})',
                  ),
                  Slider(
                    min: 0,
                    max: 5,
                    divisions: 10,
                    value: _selectedMinRating,
                    onChanged: (val) {
                      setModalState(() => _selectedMinRating = val);
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      applyFilters();
                    },
                    child: Text('Apply filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _highlightQuery(String text, String query) {
    if (query.isEmpty) return Text(text);
    final pattern = RegExp(RegExp.escape(query), caseSensitive: false);
    final matches = pattern.allMatches(text);

    List<TextSpan> spans = [];
    int start = 0;
    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: TextStyle(
            backgroundColor: Colors.yellowAccent,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.white),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int cartCount = context.watch<CartProvider>().cart['totalQuantity'];
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                          },
                          icon: Icon(Icons.clear),
                          tooltip: 'Clear search',
                        )
                      : null,
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: (value) => searchProducts(value),
              )
            : Text('Products'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/orders'),
            icon: Icon(Icons.receipt_long),
            tooltip: 'Orders',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/wishlist',
                arguments: {'products': products},
              );
            },
            icon: Icon(Icons.favorite),
            tooltip: 'Wishlist',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: Icon(Icons.person),
          ),
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort),
            onSelected: _onSortSelected,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortOption.ratingDesc,
                child: Text('Rating (High to Low)'),
              ),
              PopupMenuItem(
                value: SortOption.ratingAsc,
                child: Text('Rating (Low to High)'),
              ),
              PopupMenuItem(
                value: SortOption.priceAsc,
                child: Text('Price (Low to High)'),
              ),
              PopupMenuItem(
                value: SortOption.priceDesc,
                child: Text('Price (High to Low)'),
              ),
              PopupMenuItem(
                value: SortOption.discountDesc,
                child: Text('Discount (High to Low)'),
              ),
              PopupMenuItem(
                value: SortOption.discountAsc,
                child: Text('Discount (Low to High)'),
              ),
            ],
            tooltip: 'Sort',
          ),
          IconButton(
            onPressed: _showFilterSheet,
            icon: Icon(Icons.filter_alt),
            tooltip: 'Filters',
          ),
          IconButton(
            onPressed: () {
              if (_isSearching) {
                _searchController.clear();
                searchProducts('');
              } else {
                if (!mounted) return;
                setState(() => _isSearching = true);
              }
            },
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: !_isSearching ? 'Search for items' : 'Cancel Search',
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                key: cartIconKey,
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
                icon: Icon(Icons.shopping_cart),
              ),
              Positioned(
                right: 8,
                top: 4,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/cart');
                  },
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
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? Center(
              child: Text(
                _isSearching
                    ? 'No products found for "${_searchController.text}"'
                    : 'No products available',
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: products.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == products.length) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final product = products[index];

                if (animationKeys.length <= index) {
                  animationKeys.add(GlobalKey<AddToCartAnimationState>());
                }

                return ListTile(
                  contentPadding: EdgeInsets.only(left: 16, right: 8),
                  leading: AddToCartAnimation(
                    key: animationKeys[index],
                    onAnimationComplete: () {},
                    cartIconKey: cartIconKey,
                    child: Image.network(product.thumbnail),
                  ),
                  title: _highlightQuery(product.title, _searchController.text),
                  subtitle: Row(
                    children: [
                      SizedBox(width: 4),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Icon(Icons.star, color: Colors.amber, size: 12),
                      SizedBox(width: 8),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 8,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '\$${(product.price * (1 - product.discountPercentage / 100)).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '- ${product.discountPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.blueAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                  trailing: Row(
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
                        iconSize: 16,
                        color: Colors.pink,
                        tooltip: 'Add to wishlist',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.symmetric(horizontal: 0),
                        constraints: BoxConstraints(),
                      ),
                      IconButton(
                        onPressed: () async {
                          animationKeys[index].currentState?.startAnimation();
                          final response = await http.put(
                            Uri.parse('https://dummyjson.com/carts/1'),
                            headers: {'content-type': 'application/json'},
                            body: json.encode({
                              'merge': true,
                              'userId': 1,
                              'products': [
                                {'id': product.id, 'quantity': 1},
                              ],
                            }),
                          );

                          if (response.statusCode == 200 ||
                              response.statusCode == 201 ||
                              response.statusCode == 301) {
                            final cartProvider = Provider.of<CartProvider>(
                              context,
                              listen: false,
                            );
                            Provider.of<CartProvider>(
                              context,
                              listen: false,
                            ).addProduct({'quantity': 1, ...product.toJson()});
                            final cartJson = json.encode(cartProvider.cart);
                            if (kIsWeb) {
                              html.window.localStorage['cart'] = cartJson;
                            } else {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString('cart', cartJson);
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to add product to cart'),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.add_shopping_cart),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.symmetric(horizontal: 0),
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
