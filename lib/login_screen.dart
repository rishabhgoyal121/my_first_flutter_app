import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';
  bool ssoSuccess = false;

  @override
  void initState() {
    super.initState();
    // For web users, skip SSO requirement
    if (kIsWeb) {
      ssoSuccess = true;
    }
  }

  Future<void> _performGoogleSignIn() async {
    try {
      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        // For web, try the old method first, then fall back to new method
        try {
          await GoogleSignIn.instance.initialize(
            clientId: dotenv.env['GOOGLE_CLIENT_ID'] ?? '',
          );
          googleUser = await GoogleSignIn.instance.authenticate();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Web sign-in requires a different implementation. Use mobile app for Google Sign In.',
              ),
            ),
          );
          return;
        }
      } else {
        // For mobile platforms
        await GoogleSignIn.instance.initialize();
        googleUser = await GoogleSignIn.instance.authenticate();
      }

      final GoogleSignInAuthentication googleAuth =
           googleUser.authentication;

      // Get access token from authorization client
      final auth = await googleUser.authorizationClient.authorizationForScopes([
        'email',
        'profile',
      ]);
      final String? accessToken = auth?.accessToken;

      // Create credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      setState(() {
        ssoSuccess = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google SSO success. Please enter username and pa ssword',
          ),
        ),
      );
    } catch (e) {
      print('Google Sign In Error: $e');
      if (!mounted) return;

      String errorMessage;
      if (e.toString().contains('canceled')) {
        errorMessage = 'Google Sign In was cancelled. Please try again.';
      } else if (e.toString().contains('connection abort')) {
        errorMessage =
            'Network connection issue. Please check your internet and try again.';
      } else if (e.toString().contains('unknown')) {
        errorMessage = 'Google Sign In encountered an issue. Please try again.';
      } else {
        errorMessage = 'Google Sign In failed. Please try again later.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.orange),
      );
    }
  }

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
              // Only show Google Sign In button for mobile platforms
              if (!kIsWeb) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await _performGoogleSignIn();
                  },
                  label: Text('Login with Google'),
                  icon: Icon(Icons.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 24),
                if (ssoSuccess) ...[
                  Text(
                    'Continue with username and password',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                ],
              ],
              // For web, show a simple title
              if (kIsWeb) ...[
                Text(
                  'Enter your credentials to login',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
              ],
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
                onPressed: (ssoSuccess || kIsWeb)
                    ? () async {
                        HapticFeedback.lightImpact();
                        if (_formKey.currentState!.validate()) {
                          final navContext = context;
                          try {
                            final response = await http.post(
                              Uri.parse('https://dummyjson.com/auth/login'),
                              headers: {'Content-type': 'application/json'},
                              body: json.encode({
                                'username': username,
                                'password': password,
                              }),
                            );
                            if (response.statusCode == 200) {
                              final data = json.decode(response.body);
                              if (kIsWeb) {
                                html.document.cookie =
                                    'accessToken=${data['accessToken']}; path=/; max-age=3600';
                                html.document.cookie =
                                    'refreshToken=${data['refreshToken']}; path=/; max-age=604800';
                              } else {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(
                                  'accessToken',
                                  data['accessToken'],
                                );
                                await prefs.setString(
                                  'refreshToken',
                                  data['refreshToken'],
                                );
                              }

                              final profileResponse = await http.get(
                                Uri.parse('https://dummyjson.com/user/me'),
                                headers: {
                                  'Authorization':
                                      'Bearer ${data['accessToken']}',
                                },
                              );

                              if (profileResponse.statusCode == 200) {
                                final profileData = json.decode(
                                  profileResponse.body,
                                );
                                if (kIsWeb) {
                                  html.window.localStorage['userProfile'] = json
                                      .encode(profileData);
                                } else {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString(
                                    'userProfile',
                                    json.encode(profileData),
                                  );
                                }
                              }

                              final addCartResponse = await http.post(
                                Uri.parse('https://dummyjson.com/carts/add'),
                                headers: {'Content-Type': 'application/json'},
                                body: json.encode({
                                  'userId':
                                      1, // Assuming a user ID of 1 for demo purposes
                                  'products': [
                                    {
                                      'id':
                                          1, // Assuming a product ID of 1 for demo purposes
                                      'quantity': 1,
                                    },
                                  ],
                                }),
                              );

                              if (!(addCartResponse.statusCode == 200 ||
                                  addCartResponse.statusCode == 201)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to create cart'),
                                  ),
                                );
                              }
                              Future.delayed(Duration(seconds: 1), () {
                                if (mounted) {
                                  Navigator.pushReplacementNamed(context, '/');
                                }
                                
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Login failed. Please try again.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            print('Error: $e');
                          }
                        }
                      }
                    : null,
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
