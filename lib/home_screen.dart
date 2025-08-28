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
import 'generated/l10n.dart';
import 'package:flutter/services.dart';

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

enum ViewType { list, grid }

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  List<Product> allProducts = [];
  bool isLoading = false;
  bool hasMore = true;
  int limit = 10;
  int skip = 0;
  late ScrollController _scrollController;
  Timer? _debounce;
  final double _heroHeight = 280;

  final double _minPrice = 0;
  final double _maxPrice = 1000;
  double _selectedMinPrice = 0;
  double _selectedMaxPrice = 1000;
  double _selectedMinRating = 0;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategorySlug;
  List<String> _brands = [];
  String? _selectedBrand;
  bool _inStockOnly = false;

  final GlobalKey cartIconKey = GlobalKey();
  // Pre-allocate a large, fixed number of animation keys to avoid resizing.
  // The value 1000 is chosen as a safe upper bound for the number of animated items that could be displayed simultaneously.
  // If your app needs to support more or fewer items, adjust this value accordingly.
  static const int maxAnimationKeys =
      1000; // Consider making this configurable if needed.
  static const int _maxAnimationKeys = maxAnimationKeys;
  late final List<GlobalKey<AddToCartAnimationState>> animationKeys;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  SortOption? _selectedSort;

  // View type: list or grid
  ViewType _viewType = ViewType.list;

  Future<void> _loadViewTypePreference() async {
    try {
      if (kIsWeb) {
        final value = html.window.localStorage['viewType'];
        if (value == 'grid') {
          if (!mounted) return;
          setState(() => _viewType = ViewType.grid);
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final value = prefs.getString('viewType');
        if (value == 'grid') {
          if (!mounted) return;
          setState(() => _viewType = ViewType.grid);
        }
      }
    } catch (_) {
      // ignore prefs errors
    }
  }

  Future<void> _saveViewTypePreference() async {
    try {
      final value = _viewType == ViewType.grid ? 'grid' : 'list';
      if (kIsWeb) {
        html.window.localStorage['viewType'] = value;
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('viewType', value);
      }
    } catch (_) {
      // ignore prefs errors
    }
  }

  Widget _buildViewTypeSwitch(BuildContext context) {
    final isList = _viewType == ViewType.list;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ToggleButtons(
              isSelected: [isList, !isList],
              borderRadius: BorderRadius.circular(24),
              constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
              fillColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.14),
              selectedColor: Theme.of(context).colorScheme.primary,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
              borderColor: Colors.transparent,
              selectedBorderColor: Colors.transparent,
              onPressed: (index) async {
                HapticFeedback.selectionClick();
                if (!mounted) return;
                setState(() {
                  _viewType = index == 0 ? ViewType.list : ViewType.grid;
                });
                await _saveViewTypePreference();
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.view_list),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.grid_view),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _gridColumnsForWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1600) return 6;
    if (width >= 1360) return 5;
    if (width >= 1100) return 4;
    if (width >= 800) return 3;
    return 2; // phones and small tablets
  }

  double _gridAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1600) return 0.9;
    if (width >= 1360) return 0.86;
    if (width >= 1100) return 0.8;
    if (width >= 800) return 0.76;
    return 0.72; // phones
  }

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
      _maxAnimationKeys,
      (_) => GlobalKey<AddToCartAnimationState>(),
    );
    _loadViewTypePreference();
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
      Uri.parse(
        'https://dummyjson.com/products?limit=$maxAnimationKeys$sortQuery',
      ),
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
        _brands = allProducts.map((p) => p.brand).toSet().toList();
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
      final matchesBrand =
          _selectedBrand == null || product.brand == _selectedBrand;
      final matchesStock = !_inStockOnly || product.stock > 0;
      return matchesCategory &&
          matchesPrice &&
          matchesRating &&
          matchesBrand &&
          matchesStock;
    }).toList();
    if (!mounted) return;
    setState(() {
      products = filtered;
      isLoading = false;
      hasMore = false;
      // animationKeys are pre-allocated, no need to resize
    });
  }

  Future<void> fetchCategories() async {
    final response = await http.get(
      Uri.parse('https://dummyjson.com/products/categories'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> cats = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        _categories = cats.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        products.clear();
        skip = 0;
        hasMore = true;
        // animationKeys are pre-allocated, no need to clear
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
        // animationKeys are pre-allocated, no need to resize
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
    HapticFeedback.lightImpact();
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
    HapticFeedback.lightImpact();
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
                  Text(AppLocalizations.of(context)!.category),
                  DropdownButton<String>(
                    value: _selectedCategorySlug,
                    hint: Text(AppLocalizations.of(context)!.selectCategory),
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
                      applyFilters();
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.priceRange(
                      _selectedMinPrice.toInt(),
                      _selectedMaxPrice.toInt(),
                    ),
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
                      applyFilters();
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.minimumRating(_selectedMinRating),
                  ),
                  Slider(
                    min: 0,
                    max: 5,
                    divisions: 10,
                    value: _selectedMinRating,
                    onChanged: (val) {
                      setModalState(() => _selectedMinRating = val);
                      applyFilters();
                    },
                  ),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.brand),
                  DropdownButton<String>(
                    value: _selectedBrand,
                    hint: Text(AppLocalizations.of(context)!.selectBrand),
                    isExpanded: true,
                    items: _brands
                        .map(
                          (brand) => DropdownMenuItem<String>(
                            value: brand,
                            child: Text(brand),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setModalState(() => _selectedBrand = val);
                      applyFilters();
                    },
                  ),
                  SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.inStockOnly),
                    value: _inStockOnly,
                    onChanged: (val) {
                      setModalState(() => _inStockOnly = val ?? false);
                      applyFilters();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.done,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      setModalState(() {
                        _selectedCategorySlug = null;
                        _selectedMinPrice = _minPrice;
                        _selectedMaxPrice = _maxPrice;
                        _selectedMinRating = 0;
                        _selectedBrand = null;
                        _inStockOnly = false;
                      });
                      // Also update the main product list
                      applyFilters();
                    },

                    child: Text(AppLocalizations.of(context)!.clearFilters),
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
    if (query.isEmpty) {
      final baseColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black;
      return Text(text, style: TextStyle(color: baseColor));
    }
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
    final baseColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    return RichText(
      text: TextSpan(
        style: TextStyle(color: baseColor),
        children: spans,
      ),
    );
  }

  void _scrollToProducts() {
    // Smoothly scroll just past the hero so the first product is visible.
    _scrollController.animateTo(
      _heroHeight,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: _heroHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Text block
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Find your next favorite',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Exclusive deals, fresh arrivals, and top-rated picks — curated for you.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          backgroundColor: Colors.yellowAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _scrollToProducts();
                        },
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text(
                          'Shop now',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Image / Illustration
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/splash_icon.png',
                      height: _heroHeight - 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                  hintText: AppLocalizations.of(context)!.searchProducts,
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            searchProducts('');
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
            : Text(AppLocalizations.of(context)!.products),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/orders');
            },
            icon: Icon(Icons.receipt_long),
            tooltip: AppLocalizations.of(context)!.orders,
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(
                context,
                '/wishlist',
                arguments: {'products': products},
              );
            },
            icon: Icon(Icons.favorite),
            tooltip: AppLocalizations.of(context)!.wishlist,
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/profile');
            },
            icon: Icon(Icons.person),
          ),
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort),
            onSelected: _onSortSelected,
            onOpened: () => HapticFeedback.lightImpact(),
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
            tooltip: AppLocalizations.of(context)!.sort,
          ),
          IconButton(
            onPressed: _showFilterSheet,
            icon: Icon(Icons.filter_alt),
            tooltip: AppLocalizations.of(context)!.filters,
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              if (_isSearching) {
                setState(() {
                  _isSearching = false;
                });
                _searchController.clear();
                searchProducts('');
              } else {
                if (!mounted) return;
                setState(() => _isSearching = true);
              }
            },
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: !_isSearching
                ? AppLocalizations.of(context)!.searchForItems
                : AppLocalizations.of(context)!.cancelSearch,
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                key: cartIconKey,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/cart');
                },
                icon: Icon(Icons.shopping_cart),
              ),
              Positioned(
                right: 8,
                top: 4,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
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
      body: _viewType == ViewType.list
          ? ListView.builder(
              controller: _scrollController,
              itemCount:
                  2 + // hero header + view switch
                  (isLoading
                      ? 1 // loader below hero
                      : (products.isEmpty
                            ? 1 // empty-state below hero
                            : products.length + (hasMore ? 1 : 0))),
              itemBuilder: (context, index) {
                // Header hero at index 0
                if (index == 0) {
                  return _buildHeroSection(context);
                }

                // View type switch at index 1
                if (index == 1) {
                  return _buildViewTypeSwitch(context);
                }

                // Content starts after hero
                final listIndex = index - 2;

                if (isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (products.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Text(
                      _isSearching
                          ? AppLocalizations.of(
                              context,
                            )!.noProductsFound(_searchController.text)
                          : AppLocalizations.of(context)!.noProductsAvailable,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                if (listIndex == products.length && hasMore) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final product = products[listIndex];

                // animationKeys are pre-generated; offset by header index
                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 16, right: 8),
                  leading: AddToCartAnimation(
                    key: animationKeys[listIndex],
                    onAnimationComplete: () {},
                    cartIconKey: cartIconKey,
                    child: Image.network(product.thumbnail),
                  ),
                  title: _highlightQuery(product.title, _searchController.text),
                  subtitle: Row(
                    children: [
                      const SizedBox(width: 4),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 8),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${(product.price * (1 - product.discountPercentage / 100)).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '- ${product.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.blueAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
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
                          HapticFeedback.lightImpact();
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
                        tooltip: AppLocalizations.of(context)!.addToWishlist,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          animationKeys[listIndex].currentState
                              ?.startAnimation();
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
                              const SnackBar(
                                content: Text('Failed to add product to cart'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            )
          : ListView(
              controller: _scrollController,
              children: [
                _buildHeroSection(context),
                _buildViewTypeSwitch(context),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (products.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Text(
                      _isSearching
                          ? AppLocalizations.of(
                              context,
                            )!.noProductsFound(_searchController.text)
                          : AppLocalizations.of(context)!.noProductsAvailable,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridColumnsForWidth(context),
                        childAspectRatio: _gridAspectRatio(context),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final bool isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        return InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailsScreen(product: product),
                              ),
                            );
                          },
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: AddToCartAnimation(
                                    key: animationKeys[index],
                                    onAnimationComplete: () {},
                                    cartIconKey: cartIconKey,
                                    child: Image.network(
                                      product.thumbnail,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      DefaultTextStyle(
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        child: _highlightQuery(
                                          product.title,
                                          _searchController.text,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            product.rating.toStringAsFixed(1),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white
                                                  : null,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '\$${(product.price * (1 - product.discountPercentage / 100)).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '\$${product.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              fontSize: 10,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              context
                                                  .read<WishlistProvider>()
                                                  .toggleWishlist(product.id);
                                            },
                                            icon: Icon(
                                              context
                                                      .watch<WishlistProvider>()
                                                      .isWishlisted(product.id)
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                            ),
                                            color: Colors.pink,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          IconButton(
                                            onPressed: () async {
                                              HapticFeedback.lightImpact();
                                              animationKeys[index].currentState
                                                  ?.startAnimation();
                                              final response = await http.put(
                                                Uri.parse(
                                                  'https://dummyjson.com/carts/1',
                                                ),
                                                headers: {
                                                  'content-type':
                                                      'application/json',
                                                },
                                                body: json.encode({
                                                  'merge': true,
                                                  'userId': 1,
                                                  'products': [
                                                    {
                                                      'id': product.id,
                                                      'quantity': 1,
                                                    },
                                                  ],
                                                }),
                                              );

                                              if (response.statusCode == 200 ||
                                                  response.statusCode == 201 ||
                                                  response.statusCode == 301) {
                                                final cartProvider =
                                                    Provider.of<CartProvider>(
                                                      context,
                                                      listen: false,
                                                    );
                                                Provider.of<CartProvider>(
                                                  context,
                                                  listen: false,
                                                ).addProduct({
                                                  'quantity': 1,
                                                  ...product.toJson(),
                                                });
                                                final cartJson = json.encode(
                                                  cartProvider.cart,
                                                );
                                                if (kIsWeb) {
                                                  html
                                                          .window
                                                          .localStorage['cart'] =
                                                      cartJson;
                                                } else {
                                                  final prefs =
                                                      await SharedPreferences.getInstance();
                                                  await prefs.setString(
                                                    'cart',
                                                    cartJson,
                                                  );
                                                }
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Failed to add product to cart',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.add_shopping_cart,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (hasMore)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
