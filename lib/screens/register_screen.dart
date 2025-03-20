import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import 'otp_verification_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _termsAndConditions;

  // Get API URL from config
  String get apiBaseUrl => AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _loadTermsAndConditions();
  }

  // Load terms and conditions from file
  Future<void> _loadTermsAndConditions() async {
    try {
      final String terms = await rootBundle.loadString(
        'assets/terms_and_conditions.txt',
      );
      setState(() {
        _termsAndConditions = terms;
      });
    } catch (e) {
      if (AppConfig.isDevelopment) {
        print('Error loading terms and conditions: $e');
      }
    }
  }

  // Show terms and conditions dialog
  void _showTermsAndConditions() {
    if (_termsAndConditions == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms and Conditions'),
          content: SingleChildScrollView(child: Text(_termsAndConditions!)),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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

  // Function to handle registration
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Terms & Conditions'),
            content: const Text('Please accept the Terms and Conditions'),
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
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Capitalize first letter of full name
      final capitalizedFullName = capitalizeFirstLetter(
        _fullNameController.text,
      );

      final requestBody = {
        'user_name': capitalizedFullName,
        'phone_number': _phoneController.text,
        'password': _passwordController.text,
        'email': _emailController.text,
      };

      // Debug prints only in development mode
      if (AppConfig.isDevelopment) {
        print('=== Development Mode API Call ===');
        print('URL: $apiBaseUrl/register');
        print('Request Body: ${jsonEncode(requestBody)}');
      }

      final response = await http.post(
        Uri.parse('$apiBaseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Debug prints only in development mode
      if (AppConfig.isDevelopment) {
        print('Response Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('==============================');
      }

      setState(() {
        _isLoading = false;
      });

      final responseData = jsonDecode(response.body);
      final responseStatus =
          responseData['status'] as int? ?? response.statusCode;

      if (responseStatus == 200) {
        // Store access token from registration response
        final prefs = await SharedPreferences.getInstance();

        // Print the response data for debugging
        print('=== Registration Success Response ===');
        print('Response Data: ${jsonEncode(responseData)}');
        print('Access Token: ${responseData['data']['access_token']}');
        print('Refresh Token: ${responseData['data']['refresh_token']}');
        print('================================');

        // Store the access token from the correct path in response
        if (responseData['data'] != null &&
            responseData['data']['access_token'] != null) {
          await prefs.setString(
            'access_token',
            responseData['data']['access_token'],
          );
          print('Access token stored successfully');
        }

        if (!mounted) return;
        // Navigate to OTP verification screen
        Navigator.pushNamed(
          context,
          '/otp-verification',
          arguments: {
            'phoneNumber': _phoneController.text,
            'source': 'register',
          },
        );
      } else {
        String errorMessage = '';

        if (responseData.containsKey('error') && responseData['error'] is Map) {
          final errorMap = responseData['error'] as Map;
          final errorMessages = <String>[];

          errorMap.forEach((field, errors) {
            if (errors is List && errors.isNotEmpty) {
              errorMessages.add(
                '${field.toString().replaceAll('_', ' ')}: ${errors.first}',
              );
            } else if (errors is String) {
              errorMessages.add(
                '${field.toString().replaceAll('_', ' ')}: $errors',
              );
            }
          });

          errorMessage = errorMessages.join('\n');
        } else {
          errorMessage =
              responseData['message'] ??
              'Registration failed. Please try again.';
        }

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Registration Error'),
              content: Text(errorMessage),
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
    } catch (e) {
      // Debug prints only in development mode
      if (AppConfig.isDevelopment) {
        print('=== Development Mode Error ===');
        print('Error during registration: $e');
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
                  : 'An error occurred during registration. Please try again.',
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
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                        'Create Account',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Full Name Field
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            ValidationBuilder()
                                .required('Full name is required')
                                .minLength(
                                  3,
                                  'Full name must be at least 3 characters',
                                )
                                .build(),
                      ),

                      SizedBox(height: isSmallScreen ? 12 : 16),

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

                      // Email Field
                      TextFormField(
                        controller: _emailController,
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

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Terms and Conditions Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            onChanged: (bool? value) {
                              setState(() {
                                _acceptedTerms = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF1A237E),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showTermsAndConditions,
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I accept the '),
                                    TextSpan(
                                      text: 'Terms and Conditions',
                                      style: TextStyle(
                                        color: const Color(0xFF1A237E),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Register Button
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                            onPressed: _register,
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
                              'Register',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?'),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text('Login'),
                          ),
                        ],
                      ),

                      // Add extra padding at the bottom to ensure everything is visible
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
