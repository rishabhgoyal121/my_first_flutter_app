import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _id = 1;
  String _username = '';
  String _email = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
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
                decoration: InputDecoration(labelText: 'Username'),
                onSaved: (value) => _username = value ?? '',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter Username' : null,
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
                        content: Text('Signing up $_username'),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    try {
                      final response = await http.post(
                        Uri.parse('https://fakestoreapi.com/users'),
                        headers: {'Content-type': 'application/json'},
                        body: json.encode({
                          'id': _id,
                          'username': _username,
                          'email': _email,
                          'password': _password,
                        }),
                      );

                      if (response.statusCode == 201 ||
                          response.statusCode == 200) {
                        final data = json.decode(response.body);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Signed up $_username successfully',
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
