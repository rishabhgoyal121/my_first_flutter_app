// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get products => 'Products';

  @override
  String get searchProducts => 'Search Products...';

  @override
  String noProductsFound(String query) {
    return 'No products found for \"$query\"';
  }

  @override
  String get noProductsAvailable => 'No products available';

  @override
  String get orders => 'Orders';

  @override
  String get wishlist => 'Wishlist';

  @override
  String get profile => 'Profile';

  @override
  String get sort => 'Sort';

  @override
  String get filters => 'Filters';

  @override
  String get searchForItems => 'Search for Items...';

  @override
  String get cancelSearch => 'Cancel Search';

  @override
  String get addToWishlist => 'Add to Wishlist';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get category => 'Category';

  @override
  String get selectCategory => 'Select Category...';

  @override
  String get selectBrand => 'Select Brand...';

  @override
  String priceRange(int min, int max) {
    return 'Price Range ($min - $max)';
  }

  @override
  String minimumRating(double rating) {
    return 'Minimum Rating ($rating)';
  }

  @override
  String get inStockOnly => 'In Stock Only';

  @override
  String get done => 'Done';
}
