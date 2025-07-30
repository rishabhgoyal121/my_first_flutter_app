import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import 'user.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  // int _id = 1;
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _city = '';
  String _street = '';
  String _houseNumber = '';
  String _zipcode = '';
  String _password = '';
  double? _lat;
  double? _long;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );
    setState(() {
      _lat = position.latitude;
      _long = position.longitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'First name'),
                  onSaved: (value) => _firstName = value ?? '',
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter First name'
                      : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Last name'),
                  onSaved: (value) => _lastName = value ?? '',
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter Last name' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => _email = value ?? '',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  onSaved: (value) => _phone = value ?? '',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter phone';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'City'),
                  onSaved: (value) => _city = value ?? '',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter city';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Street'),
                  onSaved: (value) => _street = value ?? '',
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter street';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'House Number'),
                  onSaved: (value) => _houseNumber = value ?? '',
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter House Number';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Zipcode'),
                  onSaved: (value) => _zipcode = value ?? '',
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter Zipcode';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Password'),
                  onSaved: (value) => _password = value ?? '',
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Signing up $_firstName $_lastName'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      try {
                        final userBox = Hive.box<User>('users');
                        final user = User(
                          firstName: _firstName,
                          lastName: _lastName,
                          email: _email,
                          phone: _phone,
                          city: _city,
                          street: _street,
                          houseNumber: _houseNumber,
                          zipcode: _zipcode,
                          password: _password,
                        );
                        await userBox.add(user);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Signed up $_firstName $_lastName successfully.'),
                          ),
                        );
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error : $e')));
                      }
                    }
                  },
                  child: Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
