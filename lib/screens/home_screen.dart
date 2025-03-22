import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otp_verification_screen.dart';
import 'edit_profile_screen.dart';
import '../config/app_config.dart';
import 'email_verification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _userName = 'Dharmendra Agrawal';
  String _userPhone = '9887175577';
  String? _profilePicUrl;

  // Dummy data for carousel
  final List<String> carouselImages = [
    'https://picsum.photos/800/400?random=1',
    'https://picsum.photos/800/400?random=2',
    'https://picsum.photos/800/400?random=3',
    'https://picsum.photos/800/400?random=4',
  ];

  // Updated buttons data
  final List<Map<String, dynamic>> buttons = [
    {'icon': Icons.calendar_today, 'label': 'Calendar'},
    {'icon': Icons.people, 'label': 'Clients'},
    {'icon': Icons.group, 'label': 'Users'},
  ];

  // Updated containers data
  final List<Map<String, dynamic>> containers = [
    {
      'title': "Today's Cases",
      'description': '100 Cases',
      'color': Colors.blue[100],
      'icon': Icons.gavel,
      'count': 100,
    },
    {
      'title': "Tomorrow's Cases",
      'description': '100 Cases',
      'color': Colors.green[100],
      'icon': Icons.event_note,
      'count': 100,
    },
    {
      'title': 'Total Cases',
      'description': '100 Cases',
      'color': Colors.orange[100],
      'icon': Icons.today,
      'count': 100,
    },
    {
      'title': 'Date Awaited Cases',
      'description': '100 Cases',
      'color': Colors.purple[100],
      'icon': Icons.pending_actions,
      'count': 100,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      // Print request details
      print('\n============= API Request Details =============');
      print('URL: ${AppConfig.apiBaseUrl}/user');
      print('Method: POST');
      print('Headers: {');
      print('  Authorization: Bearer $accessToken');
      print('  Content-Type: application/json');
      print('}');
      print('Body: {}');
      print('=============================================\n');

      // Call user API endpoint with POST method
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}), // Empty body for POST request
      );

      // Print response details
      print('\n============= API Response Details =============');
      print('Status Code: ${response.statusCode}');
      print('Headers: {');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });
      print('}');
      print('Body: ${response.body}');
      print('==============================================\n');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Print parsed response data
        print('\n============= Parsed Response Data =============');
        print('Raw Response: $responseData');
        print('==============================================\n');

        // Extract user data from nested structure
        final userDataList = responseData['data']['userData'] as List;
        if (userDataList.isNotEmpty) {
          final userData = userDataList[0]; // Get first user from the list

          // Print user data details
          print('\n============= User Data Details =============');
          print('ID: ${userData['id']}');
          print('Name: ${userData['user_name']}');
          print('Phone: ${userData['phone_number']}');
          print('Email: ${userData['email']}');
          print('User Type: ${userData['user_type']}');
          print('Profile Image: ${userData['user_profile_image']}');
          print('Phone Verified: ${userData['is_phone_number_verified']}');
          print('Email Verified: ${userData['is_email_verified']}');
          print('First Login: ${userData['is_first_login']}');
          print('==============================================\n');

          // Check verification status
          if (userData['is_phone_number_verified'] == false) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => OTPVerificationScreen(
                        phoneNumber: userData['phone_number']?.toString() ?? '',
                        source: 'login',
                      ),
                ),
              );
            }
            return;
          }

          if (userData['is_email_verified'] == false) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EmailVerificationScreen(
                    email: userData['email'] ?? '',
                    accessToken: accessToken,
                  ),
                ),
              );
            }
            return;
          }

          if (userData['is_first_login'] == true) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            }
            return;
          }

          // Update user data in SharedPreferences
          await prefs.setString('user_name', userData['user_name'] ?? 'User');
          await prefs.setString(
            'user_phone',
            userData['phone_number']?.toString() ?? 'Phone',
          );
          await prefs.setString(
            'profile_pic_url',
            userData['user_profile_image'],
          );

          setState(() {
            _userName = userData['user_name'] ?? 'User';
            _userPhone = userData['phone_number']?.toString() ?? 'Phone';
            _profilePicUrl = userData['user_profile_image'];
            _isLoading = false;
          });
        } else {
          throw Exception('No user data found in response');
        }
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load user data. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Advocate',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '$_userName $_userPhone',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Profile Picture
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child:
                  _profilePicUrl != null
                      ? ClipOval(
                        child: Image.network(
                          _profilePicUrl!,
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, color: Colors.blue);
                          },
                        ),
                      )
                      : const Icon(Icons.person, color: Colors.blue),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child:
                        _profilePicUrl != null
                            ? ClipOval(
                              child: Image.network(
                                _profilePicUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.blue,
                                  );
                                },
                              ),
                            )
                            : const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.blue,
                            ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _userPhone,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await _logout(); // Wait for logout to complete
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel Widget with reduced height
            FlutterCarousel(
              options: CarouselOptions(
                height: 170.0, // Reduced height by ~15%
                showIndicator: true,
                slideIndicator: const CircularSlideIndicator(),
                enableInfiniteScroll: true,
                autoPlay: true,
                viewportFraction: 0.8,
                enlargeCenterPage: true,
                autoPlayCurve: Curves.fastOutSlowIn,
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
              ),
              items:
                  carouselImages.map((image) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            image: DecorationImage(
                              image: NetworkImage(image),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),

            const SizedBox(height: 20),

            // Buttons Row for main actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    buttons.map((button) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue[50],
                            child: IconButton(
                              icon: Icon(button['icon'], color: Colors.blue),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            button['label'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text(
                        'Add New Case',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text(
                        'Download Today Cases',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Case List Label
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Case List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 16),

            // Containers Grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children:
                    containers.map((container) {
                      return Container(
                        decoration: BoxDecoration(
                          color: container['color'],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              container['icon'],
                              size: 40,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              container['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${container['count']} Cases',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
