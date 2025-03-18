# Diary App

A Flutter application with responsive design and a registration page.

## Features

- Responsive design that works on mobile, tablet, and desktop
- Registration page with the following fields:
  - Username
  - Phone number
  - Email
  - Password
  - Confirm password
- Form validation
- Light and dark theme support

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Android Studio / VS Code
- Android emulator or physical device

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Project Structure

```
lib/
├── main.dart              # Entry point of the application
├── models/                # Data models
│   └── user_model.dart    # User model
├── screens/               # App screens
│   └── register_screen.dart # Registration screen
├── utils/                 # Utility classes
│   ├── app_theme.dart     # Theme configuration
│   └── validators.dart    # Form validation functions
└── widgets/               # Reusable widgets
```

## Dependencies

- [responsive_framework](https://pub.dev/packages/responsive_framework) - For responsive UI
- [form_validator](https://pub.dev/packages/form_validator) - For form validation
- [flutter_svg](https://pub.dev/packages/flutter_svg) - For SVG support
- [shared_preferences](https://pub.dev/packages/shared_preferences) - For local storage

## License

This project is licensed under the MIT License - see the LICENSE file for details.
