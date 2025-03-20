import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Legal Diary',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder:
          (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: [
              const Breakpoint(start: 0, end: 360, name: 'SMALL_MOBILE'),
              const Breakpoint(start: 361, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/otp') {
          final phoneNumber = settings.arguments as String;
          return MaterialPageRoute(
            builder:
                (context) => OTPVerificationScreen(
                  phoneNumber: phoneNumber,
                  source:
                      'login', // Default to login source for backward compatibility
                ),
          );
        }
        return null;
      },
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/otp-verification': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return OTPVerificationScreen(
            phoneNumber: args['phoneNumber'],
            source: args['source'],
          );
        },
      },
    );
  }
}
