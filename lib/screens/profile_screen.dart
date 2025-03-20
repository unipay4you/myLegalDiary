import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  Map<String, dynamic>? _userData;

  // Get API URL from config
  String get apiBaseUrl => AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Function to capitalize first letter of each word
  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  // Load user data from API
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await http.get(
        Uri.parse('$apiBaseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (AppConfig.isDevelopment) {
        print('=== Development Mode API Call ===');
        print('URL: $apiBaseUrl/profile');
        print('Response Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('==============================');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _userData = responseData;
          _fullNameController.text = responseData['user_name'] ?? '';
          _emailController.text = responseData['email'] ?? '';
          _phoneController.text = responseData['phone_number'] ?? '';
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile data');
      }
    } catch (e) {
      if (AppConfig.isDevelopment) {
        print('=== Development Mode Error ===');
        print('Error loading profile: $e');
        print('===========================');
      }

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(
              AppConfig.isDevelopment
                  ? 'Development Error: ${e.toString()}'
                  : 'Failed to load profile data. Please try again.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Update user profile
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final requestBody = {
        'user_name': capitalizeFirstLetter(_fullNameController.text),
        'email': _emailController.text,
        'phone_number': _phoneController.text,
      };

      if (AppConfig.isDevelopment) {
        print('=== Development Mode API Call ===');
        print('URL: $apiBaseUrl/profile/update');
        print('Request Body: ${jsonEncode(requestBody)}');
      }

      final response = await http.put(
        Uri.parse('$apiBaseUrl/profile/update'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (AppConfig.isDevelopment) {
        print('Response Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('==============================');
      }

      if (response.statusCode == 200) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        _loadUserData(); // Reload user data
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      if (AppConfig.isDevelopment) {
        print('=== Development Mode Error ===');
        print('Error updating profile: $e');
        print('===========================');
      }

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(
              AppConfig.isDevelopment
                  ? 'Development Error: ${e.toString()}'
                  : 'Failed to update profile. Please try again.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: isSmallScreen ? 40 : 50,
                    backgroundColor: Colors.blue,
                    child: Text(
                      _userData?['user_name']?[0].toUpperCase() ?? '?',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Text(
                    _userData?['user_name'] ?? 'Loading...',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 24),

            // Profile Fields
            TextFormField(
              controller: _fullNameController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator:
                  ValidationBuilder()
                      .required('Full name is required')
                      .minLength(3, 'Full name must be at least 3 characters')
                      .build(),
            ),

            SizedBox(height: isSmallScreen ? 12 : 16),

            TextFormField(
              controller: _emailController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator:
                  ValidationBuilder()
                      .required('Email is required')
                      .email('Please enter a valid email')
                      .build(),
            ),

            SizedBox(height: isSmallScreen ? 12 : 16),

            TextFormField(
              controller: _phoneController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator:
                  ValidationBuilder()
                      .required('Phone number is required')
                      .phone('Please enter a valid phone number')
                      .build(),
            ),

            SizedBox(height: isSmallScreen ? 24 : 32),

            // Edit/Save Button
            if (_isEditing)
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
