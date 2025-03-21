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
  bool _isLoading = true;
  bool _isEditing = false;
  Map<String, dynamic>? _userData;
  String _userName = 'Dharmendra Agrawal';
  String _userPhone = '9887175577';
  String? _profilePicUrl;

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

      // Load cached data first
      setState(() {
        _userName = prefs.getString('user_name') ?? 'User';
        _userPhone = prefs.getString('user_phone') ?? '';
        _profilePicUrl = prefs.getString('profile_pic_url');
        _fullNameController.text = _userName;
        _emailController.text = prefs.getString('user_email') ?? '';
        _phoneController.text = _userPhone;
      });

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      if (AppConfig.isDevelopment) {
        print('=== Development Mode API Call ===');
        print('URL: $apiBaseUrl/profile');
        print('Token: $accessToken');
      }

      final response = await http.get(
        Uri.parse('$apiBaseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (AppConfig.isDevelopment) {
        print('Response Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('==============================');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Save the new data to SharedPreferences
        await prefs.setString(
          'user_name',
          responseData['user_name'] ?? _userName,
        );
        await prefs.setString(
          'user_phone',
          responseData['phone_number'] ?? _userPhone,
        );
        await prefs.setString(
          'user_email',
          responseData['email'] ?? _emailController.text,
        );
        if (responseData['profile_pic_url'] != null) {
          await prefs.setString(
            'profile_pic_url',
            responseData['profile_pic_url'],
          );
        }

        setState(() {
          _userData = responseData;
          _fullNameController.text = responseData['user_name'] ?? _userName;
          _emailController.text =
              responseData['email'] ?? _emailController.text;
          _phoneController.text = responseData['phone_number'] ?? _userPhone;
          _userName = responseData['user_name'] ?? _userName;
          _userPhone = responseData['phone_number'] ?? _userPhone;
          _profilePicUrl = responseData['profile_pic_url'] ?? _profilePicUrl;
        });
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await prefs.remove('access_token');
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Session expired. Please login again.');
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load profile data');
      }
    } catch (e) {
      if (AppConfig.isDevelopment) {
        print('=== Development Mode Error ===');
        print('Error loading profile: $e');
        print('===========================');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppConfig.isDevelopment
                ? 'Development Error: ${e.toString()}'
                : 'Failed to load profile data. Using cached data.',
          ),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(label: 'Retry', onPressed: _loadUserData),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.blue,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child:
                        _profilePicUrl != null
                            ? ClipOval(
                              child: Image.network(
                                _profilePicUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.blue,
                                  );
                                },
                              ),
                            )
                            : const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.blue,
                            ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userPhone,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Profile Information Section
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTile('Email', _emailController.text, Icons.email),
                  _buildInfoTile(
                    'Address',
                    'Court Area, City Name',
                    Icons.location_on,
                  ),
                  _buildInfoTile('Bar Council ID', 'BAR123456', Icons.badge),
                  _buildInfoTile('Practice Area', 'Civil Law', Icons.gavel),
                  _buildInfoTile('Experience', '15 Years', Icons.timeline),

                  const SizedBox(height: 24),
                  const Text(
                    'Statistics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatisticCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStatisticItem('Total Cases', '150'),
          const Divider(),
          _buildStatisticItem('Active Cases', '45'),
          const Divider(),
          _buildStatisticItem('Completed Cases', '105'),
          const Divider(),
          _buildStatisticItem('Success Rate', '85%'),
        ],
      ),
    );
  }

  Widget _buildStatisticItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
