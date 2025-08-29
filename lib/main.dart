import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/product.dart';
import 'package:my_first_flutter_app/product_details_screen.dart';
import 'package:my_first_flutter_app/profile_screen.dart';
import 'orders_screen.dart';
import 'package:provider/provider.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'cart_screen.dart';
import 'cart_provider.dart';
import 'order_provider.dart';
import 'checkout_screen.dart';
import 'wishlist_provider.dart';
import 'wishlist_screen.dart';
import 'edit_profile_screen.dart';
import 'order_placed_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Preserve native splash until initialization is complete
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await dotenv.load();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  NotificationService().init();

  // Simulate extra startup work; adjust duration as needed
  await Future.delayed(const Duration(seconds: 1));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: MyApp(),
    ),
  );

  // Remove splash once app is ready
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final baseLight = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.amberAccent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigoAccent,
          foregroundColor: Colors.amberAccent,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.indigoAccent),
      ),
    );

    final baseDark = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.amberAccent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.amberAccent,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.amberAccent),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.white70),
        floatingLabelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white60),
        helperStyle: TextStyle(color: Colors.white70),
        errorStyle: TextStyle(color: Colors.redAccent),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white38),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white70,
        selectionColor: Color(0x66FFFFFF),
        selectionHandleColor: Colors.white70,
      ),
    );

    // Fonts: Inter for body/UI, Poppins for display (H1–H3)
    final textThemeLight = GoogleFonts.interTextTheme(baseLight.textTheme)
        .copyWith(
          displayLarge: GoogleFonts.poppins(
            textStyle: baseLight.textTheme.displayLarge,
          ),
          displayMedium: GoogleFonts.poppins(
            textStyle: baseLight.textTheme.displayMedium,
          ),
          displaySmall: GoogleFonts.poppins(
            textStyle: baseLight.textTheme.displaySmall,
          ),
          headlineLarge: GoogleFonts.poppins(
            textStyle: baseLight.textTheme.headlineLarge,
          ),
          headlineMedium: GoogleFonts.poppins(
            textStyle: baseLight.textTheme.headlineMedium,
          ),
          headlineSmall: GoogleFonts.poppins(
            textStyle: baseLight.textTheme.headlineSmall,
          ),
          titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
          titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
          bodyLarge: GoogleFonts.inter(),
          bodyMedium: GoogleFonts.inter(),
          bodySmall: GoogleFonts.inter(),
          labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
          labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
          labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: Colors.black87, displayColor: Colors.black87);

    final textThemeDark = GoogleFonts.interTextTheme(baseDark.textTheme)
        .copyWith(
          displayLarge: GoogleFonts.poppins(
            textStyle: baseDark.textTheme.displayLarge,
          ),
          displayMedium: GoogleFonts.poppins(
            textStyle: baseDark.textTheme.displayMedium,
          ),
          displaySmall: GoogleFonts.poppins(
            textStyle: baseDark.textTheme.displaySmall,
          ),
          headlineLarge: GoogleFonts.poppins(
            textStyle: baseDark.textTheme.headlineLarge,
          ),
          headlineMedium: GoogleFonts.poppins(
            textStyle: baseDark.textTheme.headlineMedium,
          ),
          headlineSmall: GoogleFonts.poppins(
            textStyle: baseDark.textTheme.headlineSmall,
          ),
          titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
          titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
          bodyLarge: GoogleFonts.inter(),
          bodyMedium: GoogleFonts.inter(),
          bodySmall: GoogleFonts.inter(),
          labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
          labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
          labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: Colors.amberAccent, displayColor: Colors.amberAccent);

    return MaterialApp(
      title: 'Flutter Demo',
      theme: baseLight.copyWith(textTheme: textThemeLight),
      darkTheme: baseDark.copyWith(textTheme: textThemeDark),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/signup': (context) => SignupScreen(),
        '/login': (context) => LoginScreen(),
        '/cart': (context) => CartScreen(),
        '/orders': (context) => OrdersScreen(),
        '/productDetails': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ProductDetailsScreen(
            product: Product.fromJson(args['product']),
          );
        },
        '/profile': (context) => ProfileScreen(),
        '/checkout': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return CheckoutScreen(
            cartTotal: args['cartTotal'],
            cartDiscountedTotal: args['cartDiscountedTotal'],
            cartItems: args['cartItems'],
          );
        },
        '/wishlist': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          final products = args?['products'] ?? [];
          return WishlistScreen(allProducts: products);
        },
        '/editProfile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return EditProfileScreen(userData: args['userData']);
        },
        '/orderPlaced': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return OrderPlacedScreen(
            order: args['order'],
            orderIndex: args['orderIndex'],
          );
        },
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message in foreground: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification Clicked!');
    });
  }
}
