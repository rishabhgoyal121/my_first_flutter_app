import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future getAccessTokenFromCookies() async {
    if (kIsWeb) {
      final cookies = html.document.cookie?.split(';') ?? [];
      for (final cookie in cookies) {
        final parts = cookie.trim().split('=');
        if (parts.length == 2 && parts[0] == 'accessToken') {
          return parts[1];
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null || token.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
      return token;
    }
  }

  Future<void> fetchProfile() async {
    final token = await getAccessTokenFromCookies();
    if (token == null) {
      setState(() {
        error = 'No access token found in cookies';
        isLoading = false;
      });
    }
    try {
      final response = await http.get(
        Uri.parse('https://dummyjson.com/user/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to fetch profile: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : userData == null
          ? Center(child: Text('No user data'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userData!['image'] != null)
                      CircleAvatar(
                        backgroundImage: NetworkImage(userData!['image']),
                        radius: 40,
                      ),
                    SizedBox(height: 16),
                    Text(
                      '${userData!['firstName']} ${userData!['lastName']}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '@${userData!['username']}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    Divider(height: 32),
                    Text('Email: ${userData!['email']}'),
                    SizedBox(height: 8),
                    Text('Phone: ${userData!['phone']}'),
                    SizedBox(height: 8),
                    Text('Gender: ${userData!['gender']}'),
                    SizedBox(height: 8),
                    Text('Birth Date: ${userData!['birthDate']}'),
                    SizedBox(height: 8),
                    Text('Age: ${userData!['age']}'),
                    SizedBox(height: 8),
                    Text('Blood Group: ${userData!['bloodGroup']}'),
                    SizedBox(height: 8),
                    Text('Height: ${userData!['height']} cm'),
                    SizedBox(height: 8),
                    Text('Weight: ${userData!['weight']} kg'),
                    SizedBox(height: 8),
                    Text('Eye Color: ${userData!['eyeColor']}'),
                    SizedBox(height: 8),
                    if (userData!['hair'] != null)
                      Text(
                        'Hair: ${userData!['hair']['color']} (${userData!['hair']['type']})',
                      ),
                    Divider(height: 32),
                    if (userData!['address'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Address:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${userData!['address']['address']}'),
                          Text(
                            '${userData!['address']['city']}, ${userData!['address']['state']} ${userData!['address']['postalCode']}',
                          ),
                          Text('${userData!['address']['country']}'),
                        ],
                      ),
                    SizedBox(height: 16),
                    if (userData!['company'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${userData!['company']['name']}'),
                          Text(
                            '${userData!['company']['title']} (${userData!['company']['department']})',
                          ),
                          if (userData!['company']['address'] != null)
                            Text(
                              '${userData!['company']['address']['city']}, ${userData!['company']['address']['state']}',
                            ),
                        ],
                      ),
                    SizedBox(height: 16),
                    if (userData!['company'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${userData!['company']['name']}'),
                          Text(
                            '${userData!['company']['title']} (${userData!['company']['department']})',
                          ),
                          if (userData!['company']['address'] != null)
                            Text(
                              '${userData!['company']['address']['city']}, ${userData!['company']['address']['state']}',
                            ),
                        ],
                      ),
                    SizedBox(height: 16),
                    // --- Add this block for bank details ---
                    if (userData!['bank'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank Details:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Card Number: ${userData!['bank']['cardNumber']}',
                          ),
                          Text('Card Type: ${userData!['bank']['cardType']}'),
                          Text(
                            'Card Expiry: ${userData!['bank']['cardExpire']}',
                          ),
                          Text('Currency: ${userData!['bank']['currency']}'),
                          Text('IBAN: ${userData!['bank']['iban']}'),
                        ],
                      ),
                    SizedBox(height: 16),
                    Text('Role: ${userData!['role']}'),
                  ],
                ),
              ),
            ),
    );
  }
}
