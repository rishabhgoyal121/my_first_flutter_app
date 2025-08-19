import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<StatefulWidget> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(
      text: widget.userData['firstName'],
    );
    lastNameController = TextEditingController(
      text: widget.userData['lastName'],
    );
    emailController = TextEditingController(text: widget.userData['email']);
    phoneController = TextEditingController(text: widget.userData['phone']);
  }

  Future<void> saveProfile() async {
    final updatedData = Map<String, dynamic>.from(widget.userData);
    updatedData['firstName'] = firstNameController.text;
    updatedData['lastName'] = lastNameController.text;
    updatedData['email'] = emailController.text;
    updatedData['phone'] = phoneController.text;

    final profileJson = json.encode(updatedData);

    if (kIsWeb) {
      html.window.localStorage['userProfile'] = profileJson;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userProfile', profileJson);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),),
            SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            SizedBox(height: 24),
            ElevatedButton(onPressed: saveProfile, child: Text('Save'))
          ],
        ),
      ),
    );
  }
}
