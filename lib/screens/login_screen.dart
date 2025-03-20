import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Get API URL from config
  String get apiBaseUrl => AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  // Function to handle login
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requestBody = {
        'phone_number': _phoneController.text,
        'password': _passwordController.text,
      };

      // Print request details for debugging
      print('\n=== Login Request Details ===');
      print('Request URL: $apiBaseUrl/login');
      print('Request Body: ${jsonEncode(requestBody)}');
      print('===========================\n');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Print response details for debugging
      print('\n=== Login Response Details ===');
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('===========================\n');

      setState(() {
        _isLoading = false;
      });

      try {
        final responseData = jsonDecode(response.body);
        print('\n=== Parsed Response Data ===');
        print('Response Data: $responseData');
        print('=========================\n');

        // Get status from response data or fallback to HTTP status code
        final responseStatus =
            responseData['status'] as int? ?? response.statusCode;

        if (responseStatus == 200) {
          // Store tokens only if they exist in the response data
          final prefs = await SharedPreferences.getInstance();

          // Get tokens from responseData['data']
          final data = responseData['data'] as Map<String, dynamic>?;
          if (data != null) {
            if (data['access_token'] != null) {
              await prefs.setString('access_token', data['access_token']);
            }
            if (data['refresh_token'] != null) {
              await prefs.setString('refresh_token', data['refresh_token']);
            }
          }

          if (!mounted) return;
          // Navigate to OTP verification screen
          Navigator.pushNamed(
            context,
            '/otp-verification',
            arguments: {
              'phoneNumber': _phoneController.text,
              'source': 'login',
            },
          );
        } else {
          // Show error dialog with message from response
          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Login Failed'),
                content: Text(
                  responseData['message'] ?? 'Login failed. Please try again.',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Clear only password field
                      _passwordController.clear();
                    },
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        print('\n=== JSON Parsing Error ===');
        print('Error parsing response: $e');
        print('Raw response that failed to parse: ${response.body}');
        print('=========================\n');

        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text(
                'Server response error. Please try again later.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Clear only password field
                    _passwordController.clear();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('\n=== Network/Other Error ===');
      print('Error during login: $e');
      print('=========================\n');

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text(
              'Network error occurred. Please check your connection and try again.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Clear only password field
                  _passwordController.clear();
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
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Company Logo
                      Container(
                        height: isSmallScreen ? 80 : 120,
                        margin: EdgeInsets.only(
                          bottom: isSmallScreen ? 16 : 32,
                        ),
                        child: SvgPicture.asset(
                          'assets/images/company_logo.svg',
                          height: isSmallScreen ? 70 : 100,
                        ),
                      ),

                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Phone Number Field
                      TextFormField(
                        controller: _phoneController,
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

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator:
                            ValidationBuilder()
                                .required('Password is required')
                                .minLength(
                                  8,
                                  'Password must be at least 8 characters',
                                )
                                .build(),
                      ),

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Login Button
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                            onPressed: _login,
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
                              'Login',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Don\'t have an account?'),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text('Register'),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
