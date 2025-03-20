import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_validator/form_validator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'dart:async';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String source; // 'login' or 'register'

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.source,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResendOTP = true;
  int _resendTimer = 30;

  // Get API URL from config
  String get apiBaseUrl => AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  // Function to handle OTP verification
  Future<void> _verifyOtp() async {
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
        throw Exception('Access token not found');
      }

      final requestBody = {
        'phone_number': widget.phoneNumber,
        'otp': _otpController.text,
      };

      // Print request details for debugging
      print('\n=== Verify OTP Request Details ===');
      print('Request URL: $apiBaseUrl/otp-verify');
      print('Request Body: ${jsonEncode(requestBody)}');
      print('===========================\n');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/otp-verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      // Print response details for debugging
      print('\n=== Verify OTP Response Details ===');
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

        final responseStatus =
            responseData['status'] as int? ?? response.statusCode;

        if (responseStatus == 200) {
          if (!mounted) return;
          await _showSuccessDialog();
        } else {
          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Verification Failed'),
                content: Text(
                  responseData['message'] ??
                      'OTP verification failed. Please try again.',
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
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('\n=== Network/Other Error ===');
      print('Error during OTP verification: $e');
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
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Function to handle resend OTP
  Future<void> _resendOtp() async {
    if (!_canResendOTP) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      final requestBody = {'phone_number': widget.phoneNumber};

      // Print request details for debugging
      print('\n=== Resend OTP Request Details ===');
      print('Request URL: $apiBaseUrl/otp-resend');
      print('Request Body: ${jsonEncode(requestBody)}');
      print('===========================\n');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/otp-resend'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      // Print response details for debugging
      print('\n=== Resend OTP Response Details ===');
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

        final responseStatus =
            responseData['status'] as int? ?? response.statusCode;

        if (responseStatus == 200) {
          if (!mounted) return;
          await _showMessageDialog(
            'Success',
            'OTP has been resent to your phone number.',
          );
          _startResendTimer();
        } else if (responseStatus == 403) {
          if (!mounted) return;
          await _showMessageDialog(
            'Error',
            'Please wait for 30 seconds before requesting new OTP.',
          );
        } else {
          if (!mounted) return;
          await _showMessageDialog(
            'Error',
            responseData['message'] ??
                'Failed to resend OTP. Please try again.',
          );
          _navigateToLogin();
        }
      } catch (e) {
        print('\n=== JSON Parsing Error ===');
        print('Error parsing response: $e');
        print('Raw response that failed to parse: ${response.body}');
        print('=========================\n');

        if (!mounted) return;
        await _showMessageDialog(
          'Error',
          'Server response error. Please try again later.',
        );
      }
    } catch (e) {
      print('\n=== Network/Other Error ===');
      print('Error during resend OTP: $e');
      print('=========================\n');

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      await _showMessageDialog(
        'Error',
        'Network error occurred. Please check your connection and try again.',
      );
    }
  }

  // Function to show success dialog
  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('OTP verified successfully.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLogin();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to show message dialog
  Future<void> _showMessageDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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

  // Function to navigate to login screen
  void _navigateToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  // Function to start resend timer
  void _startResendTimer() {
    setState(() {
      _canResendOTP = false;
      _resendTimer = 30;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResendOTP = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
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
                      Text(
                        'OTP Verification',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      Text(
                        'Enter the OTP sent to ${widget.phoneNumber}',
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // OTP Input Field
                      TextFormField(
                        controller: _otpController,
                        decoration: const InputDecoration(
                          labelText: 'Enter OTP',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: ValidationBuilder()
                            .required('OTP is required')
                            .minLength(6, 'OTP must be 6 digits')
                            .maxLength(6, 'OTP must be 6 digits')
                            .build(),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Verify Button
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

                      // Resend OTP Link with Timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code?",
                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          ),
                          TextButton(
                            onPressed: _canResendOTP ? _resendOtp : null,
                            child: Text(
                              _canResendOTP
                                  ? 'Resend'
                                  : 'Resend (${_resendTimer}s)',
                              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                            ),
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
