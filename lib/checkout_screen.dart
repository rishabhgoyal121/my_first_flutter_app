import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final double cartTotal;
  final double cartDiscountedTotal;
  final List<dynamic> cartItems;

  const CheckoutScreen({
    super.key,
    required this.cartTotal,
    required this.cartDiscountedTotal,
    required this.cartItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String _address = '';
  String _city = '';
  String _state = '';
  String _stateCode = '';
  String _postalCode = '';
  String _country = '';
  double? _latitude;
  double? _longitude;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _stateCodeController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final String? userProfileString;
    if (kIsWeb) {
      userProfileString = html.window.localStorage['userProfile'];
    } else {
      final prefs = await SharedPreferences.getInstance();
      userProfileString = prefs.getString('userProfile');
    }
    if (userProfileString != null) {
      final userProfile = jsonDecode(userProfileString)['address'];
      if (!mounted) return;
      setState(() {
        _addressController.text = (userProfile['address'] ?? '').toString();
        _cityController.text = (userProfile['city'] ?? '').toString();
        _stateController.text = (userProfile['state'] ?? '').toString();
        _stateCodeController.text = (userProfile['stateCode'] ?? '').toString();
        _postalCodeController.text = (userProfile['postalCode'] ?? '')
            .toString();
        _countryController.text = (userProfile['country'] ?? '').toString();
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _stateCodeController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not find location: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Address'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter Address' : null,
                  onSaved: (newValue) => _address = newValue ?? '',
                ),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(labelText: 'City'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter City' : null,
                  onSaved: (newValue) => _city = newValue ?? '',
                ),
                TextFormField(
                  controller: _stateController,
                  decoration: InputDecoration(labelText: 'State'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter State' : null,
                  onSaved: (newValue) => _state = newValue ?? '',
                ),
                TextFormField(
                  controller: _stateCodeController,
                  decoration: InputDecoration(labelText: 'State Code'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter State Code'
                      : null,
                  onSaved: (newValue) => _stateCode = newValue ?? '',
                ),
                TextFormField(
                  controller: _postalCodeController,
                  decoration: InputDecoration(labelText: 'Postal Code'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter Postal Code'
                      : null,
                  onSaved: (newValue) => _postalCode = newValue ?? '',
                ),
                TextFormField(
                  controller: _countryController,
                  decoration: InputDecoration(labelText: 'Country'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter Country' : null,
                  onSaved: (newValue) => _country = newValue ?? '',
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _getCurrentLocation,
                      child: Text('Get Location'),
                    ),
                    SizedBox(height: 16),
                    if (_latitude != null && _longitude != null)
                      Text(
                        '  Lat: ${_latitude!.toStringAsFixed(4)} Lng: ${_longitude!.toStringAsFixed(4)}',
                      )
                    else
                      Text('  Location not set'),
                  ],
                ),
                SizedBox(height: 24),
                Text('Total: \$${widget.cartTotal.toStringAsFixed(2)}'),
                Text(
                  'Discounted Total: \$${widget.cartDiscountedTotal.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      if (_latitude == null || _longitude == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please set your location before placing the order.',
                            ),
                          ),
                        );
                        return;
                      }
                      _formKey.currentState?.save();
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            address: {
                              'address': _address,
                              'city': _city,
                              "state": _state,
                              'stateCode': _stateCode,
                              'postalCode': _postalCode,
                              'country': _country,
                              'coordinates': {
                                'lat': _latitude,
                                'lng': _longitude,
                              },
                            },
                            cartTotal: widget.cartTotal,
                            cartDiscountedTotal: widget.cartDiscountedTotal,
                            cartItems: widget.cartItems,
                          ),
                        ),
                      );
                      if (result != null &&
                          result is Map &&
                          result['orderPlaced'] == true) {
                        Navigator.pop(context, result);
                      }
                    }
                  },
                  child: Text('Continue to Payment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
