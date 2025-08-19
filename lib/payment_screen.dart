import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> address;
  final double cartTotal;
  final double cartDiscountedTotal;
  final List<dynamic> cartItems;

  const PaymentScreen({
    super.key,
    required this.address,
    required this.cartTotal,
    required this.cartDiscountedTotal,
    required this.cartItems,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = 'Credit Card';

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBankInfo();
  }

  Future<void> _loadBankInfo() async {
    String? userProfileString;
    if (kIsWeb) {
      userProfileString = html.window.localStorage['userProfile'];
    } else {
      final prefs = await SharedPreferences.getInstance();
      userProfileString = prefs.getString('userProfile');
    }
    if (userProfileString != null) {
      final userProfile = jsonDecode(userProfileString);
      final bank = userProfile['bank'] ?? {};
      if (!mounted) return;
      setState(() {
        _cardNumberController.text = (bank['cardNumber'] ?? '').toString();
        _expiryDateController.text = (bank['cardExpire'] ?? '').toString();
        _ibanController.text = (bank['iban'] ?? '').toString();
      });
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField(
                  initialValue: _paymentMethod,
                  items: [
                    DropdownMenuItem(
                      value: 'Credit Card',
                      child: Text('Credit Card'),
                    ),
                    DropdownMenuItem(value: 'IBAN', child: Text('IBAN')),
                  ],
                  onChanged: (value) {
                    if (!mounted) return;
                    setState(() {
                      _paymentMethod = value ?? 'Credit Card';
                    });
                  },
                ),
                if (_paymentMethod == 'Credit Card') ...[
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: InputDecoration(labelText: 'Card Number'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter Card Number'
                        : null,
                  ),
                  TextFormField(
                    controller: _expiryDateController,
                    decoration: InputDecoration(labelText: 'Expiry Date'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter Expiry Date'
                        : null,
                  ),
                ],
                if (_paymentMethod == 'IBAN') ...[
                  TextFormField(
                    controller: _ibanController,
                    decoration: InputDecoration(labelText: 'IBAN'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter IBAN' : null,
                  ),
                ],
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context, {'orderPlaced': true});
                    }
                  },
                  child: Text('Place Order'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
