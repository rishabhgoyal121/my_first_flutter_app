import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Username'),
                onChanged: (val) => username = val,
                validator: (val) => val!.isEmpty ? 'Enter Username' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                onChanged: (val) => password = val,
                validator: (val) => val!.isEmpty ? 'Enter Password' : null,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final navContext = context;
                    try {
                      final response = await http.post(
                        Uri.parse('https://dummyjson.com/auth/login'),
                        headers: {'Content-type': 'application/json'},
                        body: json.encode({'username': username, 'password': password}),
                      );
                      if (response.statusCode == 200) {
                        final data = json.decode(response.body);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Welcome ${data['username']}')),
                        );
                        Future.delayed(Duration(seconds: 1), () {
                          Navigator.pushReplacementNamed(navContext, '/');
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Login failed. Please try again.')),
                        );
                      }
                    } catch (e) {
                      print('Error: $e');
                    }
                  }
                },
                child: Text('Login'),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: Text('Don\'t have an account? Sign up.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
