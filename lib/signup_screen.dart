import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _id = 1;
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
    _fetchUsers();
    _getLocation();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('https://fakestoreapi.com/users'),
      );
      if (response.statusCode == 200) {
        final List decoded = json.decode(response.body);
        int lastId = decoded.isNotEmpty ? decoded.last['id'] as int : 0;
        setState(() {
          _id = lastId + 1;
        });
        print('lastId : $lastId');
      } else {
        print('Failed to fetch users : ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users : $e');
    }
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'First name'),
                onSaved: (value) => _firstName = value ?? '',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter First name' : null,
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
                      final response = await http.post(
                        Uri.parse('https://fakestoreapi.com/users'),
                        headers: {'Content-type': 'application/json'},
                        body: json.encode({
                          'id': _id,
                          'firstname': _firstName,
                          'lastname': _lastName,
                          'email': _email,
                          'password': _password,
                        }),
                      );

                      if (response.statusCode == 201 ||
                          response.statusCode == 200) {
                        final data = json.decode(response.body);
                        print('data is $data');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Signed up $_firstName $_lastName successfully',
                            ),
                          ),
                        );
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Sign up failed ${response.statusCode}',
                            ),
                          ),
                        );
                      }
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
    );
  }
}
