import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

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

  Future<void> fetchProfile() async {
    String? profileJson;
    if (kIsWeb) {
      profileJson = html.window.localStorage['userProfile'];
    } else {
      final prefs = await SharedPreferences.getInstance();
      profileJson = prefs.getString('userProfile');
    }
    if (profileJson == null) {
      if (!mounted) return;
      setState(() {
        error = 'Profile data not found in local storage';
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        userData = json.decode(profileJson!);
        isLoading = false;
      });
    }
  }

  Future<void> pickAndUploadImage() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final apiKey = dotenv.env['IMGBB_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Missing image upload API key. Please set IMGBB_API_KEY.',
          ),
        ),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
      body: {'image': base64Image},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final imageUrl = data['data']['url'];

      if (!mounted) return;
      setState(() {
        userData!['image'] = imageUrl;
      });

      final userDataJson = json.encode(userData);

      if (kIsWeb) {
        html.window.localStorage['userProfile'] = userDataJson;
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userProfile', userDataJson);
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          if (!isLoading && error == null && userData != null)
            IconButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                final updated = await Navigator.pushNamed(
                  context,
                  '/editProfile',
                  arguments: {'userData': userData},
                );
                if (updated == true) {
                  fetchProfile();
                }
              },
              icon: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.indigo.withValues(alpha: 0.15),
                child: Icon(
                  Icons.edit_outlined,
                  size: 26,
                  color: Colors.deepOrange,
                ),
              ),
              tooltip: 'Edit Profile', // Tooltip for accessibility
              splashRadius: 28, // Larger splash for easier tap
            ),
        ],
      ),
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
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(userData!['image']),
                              radius: 40,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: pickAndUploadImage,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
