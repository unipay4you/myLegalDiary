import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;
  final String apiBaseUrl = 'https://mylegaldiary.in/api';

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCode;

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the stored tokens
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      // Create request body
      final requestBody = {'phone_number': widget.phoneNumber, 'otp': otp};

      // Log API call details
      print('=== API CALL DETAILS ===');
      print('API Endpoint: $apiBaseUrl/verify-otp');
      print('Method: POST');
      print(
        'Headers: {"Content-Type": "application/json", "Authorization": "Bearer $accessToken"}',
      );
      print('Request Body: ${jsonEncode(requestBody)}');
      print('========================');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      // Log response details
      print('=== API RESPONSE DETAILS ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('============================');

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        // OTP verification successful
        final responseData = jsonDecode(response.body);

        // Update tokens if provided in the response
        if (responseData['access_token'] != null) {
          await prefs.setString('access_token', responseData['access_token']);
        }
        if (responseData['refresh_token'] != null) {
          await prefs.setString('refresh_token', responseData['refresh_token']);
        }

        // Navigate to home screen or dashboard
        if (!mounted) return;
        // TODO: Replace with your home screen navigation
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        // OTP verification failed
        final responseData = jsonDecode(response.body);

        // Check if the response contains error field with specific field errors
        if (responseData.containsKey('error') && responseData['error'] is Map) {
          final errorMap = responseData['error'] as Map;
          final errorMessages = <String>[];

          // Process each field error
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

          // Join all error messages
          final errorMessage = errorMessages.join('\n');

          setState(() {
            _errorMessage = errorMessage;
          });
        } else {
          // Fallback to generic error message
          setState(() {
            _errorMessage =
                responseData['message'] ??
                'OTP verification failed. Please try again.';
          });
        }
      }
    } catch (e) {
      print('Error during OTP verification: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create request body
      final requestBody = {'phone_number': widget.phoneNumber};

      // Log API call details
      print('=== API CALL DETAILS ===');
      print('API Endpoint: $apiBaseUrl/resend-otp');
      print('Method: POST');
      print('Headers: {"Content-Type": "application/json"}');
      print('Request Body: ${jsonEncode(requestBody)}');
      print('========================');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Log response details
      print('=== API RESPONSE DETAILS ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('============================');

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        // OTP resent successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP has been resent to your phone'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Failed to resend OTP
        final responseData = jsonDecode(response.body);

        // Check if the response contains error field with specific field errors
        if (responseData.containsKey('error') && responseData['error'] is Map) {
          final errorMap = responseData['error'] as Map;
          final errorMessages = <String>[];

          // Process each field error
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

          // Join all error messages
          final errorMessage = errorMessages.join('\n');

          setState(() {
            _errorMessage = errorMessage;
          });
        } else {
          // Fallback to generic error message
          setState(() {
            _errorMessage =
                responseData['message'] ??
                'Failed to resend OTP. Please try again.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final otpBoxSize = isSmallScreen ? 40.0 : 45.0;

    return Scaffold(
      // Allow screen to resize with keyboard for better visibility
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('OTP Verification')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Verify Your Phone',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  'We have sent a verification code to ${widget.phoneNumber}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 30 : 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: otpBoxSize,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) => _onOtpDigitChanged(index, value),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                if (_errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _verifyOtp,
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
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code?",
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                    TextButton(
                      onPressed: _resendOtp,
                      child: Text(
                        'Resend',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      ),
                    ),
                  ],
                ),
                // Add extra padding at the bottom
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
