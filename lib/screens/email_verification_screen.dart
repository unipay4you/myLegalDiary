import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String accessToken;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.accessToken,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all saved data

      if (mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error during logout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _logout(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Check your email and verify your account before logging in.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    print('\n=== Resend Email Request ===');
                    print('Request URL: ${AppConfig.apiBaseUrl}/email-resend');
                    print('Request Headers:');
                    print('  Authorization: Bearer ${widget.accessToken}');
                    print('  Content-Type: application/json');
                    print('Request Body: {"email": "${widget.email}"}');
                    print('===========================\n');

                    final response = await http.post(
                      Uri.parse('${AppConfig.apiBaseUrl}/email-resend'),
                      headers: {
                        'Authorization': 'Bearer ${widget.accessToken}',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({'email': widget.email}),
                    );

                    print('\n=== Resend Email Response ===');
                    print('Response Status Code: ${response.statusCode}');
                    print('Response Headers:');
                    response.headers.forEach((key, value) {
                      print('  $key: $value');
                    });
                    print('Response Body: ${response.body}');
                    print('===========================\n');

                    if (response.statusCode == 200) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Verification email has been resent. Please check your inbox.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      final errorData = json.decode(response.body);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              errorData['message'] ??
                                  'Failed to resend verification email. Please try again later.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print('Error resending email: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Error resending verification email. Please try again later.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Resend Verification Email'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  String newEmail = '';
                  bool isEmailValid = false;

                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Change Email'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'New Email Address',
                                  hintText: 'Enter your new email',
                                  errorMaxLines: 2,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (value) {
                                  newEmail = value;
                                  isEmailValid = RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  ).hasMatch(value);
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (!isEmailValid) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid email address',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  print(
                                    '\n============= Change Email Request =============',
                                  );
                                  print(
                                    'URL: ${AppConfig.apiBaseUrl}/changeemail',
                                  );
                                  print('Method: POST');
                                  print('Headers: {');
                                  print(
                                    '  Authorization: Bearer ${widget.accessToken}',
                                  );
                                  print('  Content-Type: application/json');
                                  print('}');
                                  print('Body: {"new_email": "$newEmail"}');
                                  print(
                                    '=============================================\n',
                                  );

                                  final response = await http.post(
                                    Uri.parse(
                                      '${AppConfig.apiBaseUrl}/changeemail',
                                    ),
                                    headers: {
                                      'Authorization':
                                          'Bearer ${widget.accessToken}',
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({'new_email': newEmail}),
                                  );

                                  print(
                                    '\n============= Change Email Response =============',
                                  );
                                  print('Status Code: ${response.statusCode}');
                                  print('Headers: {');
                                  response.headers.forEach((key, value) {
                                    print('  $key: $value');
                                  });
                                  print('}');
                                  print('Body: ${response.body}');
                                  print(
                                    '==============================================\n',
                                  );

                                  if (response.statusCode == 200) {
                                    Navigator.pop(context); // Close dialog
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Email changed successfully. Please login again and verify your new email.',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );

                                      // Clear all saved data and navigate to login
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.clear();

                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => const LoginScreen(),
                                        ),
                                        (Route<dynamic> route) => false,
                                      );
                                    }
                                  } else {
                                    final errorData = json.decode(
                                      response.body,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            errorData['message'] ??
                                                'Failed to change email. Please try again.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  print('Error changing email: $e');
                                  Navigator.pop(context); // Close dialog
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Error changing email. Please try again later.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Submit'),
                            ),
                          ],
                        ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Change Email'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
