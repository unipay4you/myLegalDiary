import 'package:flutter/material.dart';

class AppConfig {
  static const bool isDevelopment = true; // Set to false for production

  // API URLs
  // For development, use your computer's local IP address instead of localhost
  // Example: If your computer's IP is 192.168.1.5, use: 'http://192.168.1.5:8000/api'
  static const String devApiBaseUrl =
      'http://10.0.2.2:8000/api'; // Special Android emulator IP for localhost
  static const String prodApiBaseUrl = 'https://mylegaldiary.in/api';

  // Get the appropriate base URL based on environment
  static String get apiBaseUrl =>
      isDevelopment ? devApiBaseUrl : prodApiBaseUrl;

  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // API Endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String verifyOtpEndpoint = '/verify-otp';
  static const String resendOtpEndpoint = '/resend-otp';
  static const String profileEndpoint = '/profile';
  static const String profileUpdateEndpoint = '/profile/update';

  // Error Messages
  static const String connectionError =
      'Unable to connect to server. Please check your internet connection.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String serverError =
      'Server error occurred. Please try again later.';
  static const String unknownError =
      'An unknown error occurred. Please try again.';

  // Success Messages
  static const String loginSuccess = 'Login successful';
  static const String registerSuccess = 'Registration successful';
  static const String otpSentSuccess = 'OTP sent successfully';
  static const String otpVerifiedSuccess = 'OTP verified successfully';
  static const String profileUpdateSuccess = 'Profile updated successfully';

  // Validation Messages
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidPhone = 'Please enter a valid phone number';
  static const String invalidOtp = 'Please enter a valid OTP';
  static const String invalidPin = 'Please enter a valid 6-digit PIN code';
}
