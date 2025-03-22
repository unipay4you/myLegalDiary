import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'dart:async';
import 'dart:io';

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
    });

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.loginEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone_number': _phoneController.text,
              'password': _passwordController.text,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(AppConfig.timeoutError);
            },
          );

      if (AppConfig.isDevelopment) {
        print('=== Development Mode API Call ===');
        print('URL: ${AppConfig.apiBaseUrl}${AppConfig.loginEndpoint}');
        print('Response Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('Response Headers: ${response.headers}');
        print('==============================');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // Check if response data exists and has required fields
        if (responseData == null || responseData['data'] == null) {
          throw Exception('Invalid response format from server');
        }

        final data = responseData['data'] as Map<String, dynamic>;

        // Store user data with null checks
        if (data['access_token'] != null) {
          await prefs.setString('access_token', data['access_token']);
        } else {
          throw Exception('Access token not found in response');
        }

        // Store optional user data with null checks
        await prefs.setString('user_name', data['user_name'] ?? '');
        await prefs.setString('user_phone', data['phone_number'] ?? '');
        await prefs.setString('user_email', data['email'] ?? '');

        if (data['profile_pic_url'] != null) {
          await prefs.setString('profile_pic_url', data['profile_pic_url']);
        }

        if (AppConfig.isDevelopment) {
          print('=== Response Data Structure ===');
          print('Response Data Type: ${responseData.runtimeType}');
          print('Response Data Keys: ${responseData.keys.toList()}');
          print('Response Data: $responseData');
          print('=============================');
        }

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? AppConfig.unknownError;
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConfig.timeoutError),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _login,
          ),
        ),
      );
    } on SocketException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConfig.connectionError),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _login,
          ),
        ),
      );
    } catch (e) {
      if (AppConfig.isDevelopment) {
        print('=== Development Mode Error ===');
        print('Error during login: $e');
        print('===========================');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppConfig.isDevelopment
                ? 'Development Error: ${e.toString()}'
                : AppConfig.unknownError,
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _login,
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
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

                      const SizedBox(height: 20),
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
