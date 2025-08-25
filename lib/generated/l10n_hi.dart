// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get products => 'उत्पाद';

  @override
  String get searchProducts => 'उत्पाद खोजें...';

  @override
  String noProductsFound(String query) {
    return '\"$query\" के लिए कोई उत्पाद नहीं मिला';
  }

  @override
  String get noProductsAvailable => 'कोई उत्पाद उपलब्ध नहीं है';

  @override
  String get orders => 'आदेश';

  @override
  String get wishlist => 'इच्छा सूची';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get sort => 'क्रमबद्ध करें';

  @override
  String get filters => 'फ़िल्टर';

  @override
  String get searchForItems => 'आइटम खोजें';

  @override
  String get cancelSearch => 'खोज रद्द करें';

  @override
  String get addToWishlist => 'इच्छा सूची में जोड़ें';

  @override
  String get applyFilters => 'फ़िल्टर लागू करें';

  @override
  String get clearFilters => 'फ़िल्टर हटाएँ';

  @override
  String get category => 'श्रेणी';

  @override
  String get selectCategory => 'श्रेणी चुनें';

  @override
  String get selectBrand => 'ब्रांड चुनें';

  @override
  String priceRange(int min, int max) {
    return 'मूल्य सीमा ($min - $max)';
  }

  @override
  String minimumRating(double rating) {
    return 'न्यूनतम रेटिंग ($rating)';
  }

  @override
  String get inStockOnly => 'केवल स्टॉक में उपलब्ध';

  @override
  String get done => 'हो गया';
}
