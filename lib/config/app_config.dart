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
}
