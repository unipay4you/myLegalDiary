import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String? _userId; // Store user ID for profile updates

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _barRegController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _address3Controller = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  File? _profileImage;
  String? _existingProfileUrl;
  String? _selectedState;
  String? _selectedDistrict;
  List<String> _states =
      []; // Changed to empty list, will be populated from API
  Map<String, List<String>> _districts =
      {}; // Changed to empty map, will be populated from API
  Map<String, String> _stateIds = {}; // Map of state name to state ID
  Map<String, String> _districtIds = {}; // Map of district name to district ID
  String? _selectedStateId; // Store selected state ID
  String? _selectedDistrictId; // Store selected district ID

  @override
  void initState() {
    super.initState();
    _fetchDistrictData();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _barRegController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _address3Controller.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _fetchDistrictData() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/getdistrict'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 200 && responseData['payload'] != null) {
          final districtList = responseData['payload'] as List;

          final Map<String, List<String>> tempDistricts = {};
          final Map<String, String> tempStateNames = {};
          final Map<String, String> tempStateIds = {};
          final Map<String, String> tempDistrictIds = {};

          // First, extract all unique states
          for (var item in districtList) {
            final stateData = item['state'] as Map<String, dynamic>;
            final String stateId = stateData['id'].toString();
            final String stateName = stateData['state'] ?? '';

            if (stateName.isNotEmpty) {
              tempStateNames[stateId] = stateName;
              tempStateIds[stateName] = stateId;
            }
          }

          // Then organize districts by state
          for (var item in districtList) {
            final String districtId = item['id'].toString();
            final String districtName = item['district'] ?? '';
            final stateData = item['state'] as Map<String, dynamic>;
            final String stateId = stateData['id'].toString();
            final String stateName = tempStateNames[stateId] ?? '';

            if (stateName.isNotEmpty && districtName.isNotEmpty) {
              if (!tempDistricts.containsKey(stateName)) {
                tempDistricts[stateName] = [];
              }
              if (!tempDistricts[stateName]!.contains(districtName)) {
                tempDistricts[stateName]!.add(districtName);
                tempDistrictIds[districtName] = districtId;
              }
            }
          }

          setState(() {
            _states = tempStateNames.values.toList()..sort();
            _districts = tempDistricts;
            _stateIds = tempStateIds;
            _districtIds = tempDistrictIds;

            _districts.forEach((state, districts) {
              districts.sort();
            });
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load district data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final userDataList = responseData['data']['userData'] as List;

        if (userDataList.isNotEmpty) {
          final userData = userDataList[0];

          print('\n============= User Profile Data =============');
          print('User Profile Image: ${userData['user_profile_image']}');
          print('============================================\n');

          setState(() {
            _userId = userData['id']?.toString();
            _nameController.text = userData['user_name'] ?? '';
            _dobController.text = userData['user_dob'] ?? '';
            _phoneController.text = userData['phone_number']?.toString() ?? '';
            _emailController.text = userData['email'] ?? '';

            final barRegNumber = userData['advocate_registration_number'];
            _barRegController.text =
                (barRegNumber == null || barRegNumber == 'None')
                    ? ''
                    : barRegNumber.toString();

            // Handle address fields
            final address1 = userData['user_address1'];
            final address2 = userData['user_address2'];
            final address3 = userData['user_address3'];

            _address1Controller.text =
                (address1 == null || address1 == 'None')
                    ? ''
                    : address1.toString();
            _address2Controller.text =
                (address2 == null || address2 == 'None')
                    ? ''
                    : address2.toString();
            _address3Controller.text =
                (address3 == null || address3 == 'None')
                    ? ''
                    : address3.toString();

            _pinController.text =
                userData['user_district_pincode']?.toString() ?? '';

            // Handle state and district from nested JSON
            final userState = userData['user_state'];
            final userDistrict = userData['user_district'];

            if (userState != null && userState is Map<String, dynamic>) {
              _selectedStateId = userState['id']?.toString() ?? '';
              _selectedState = userState['state']?.toString() ?? '';
            }

            if (userDistrict != null && userDistrict is Map<String, dynamic>) {
              _selectedDistrictId = userDistrict['id']?.toString() ?? '';
              _selectedDistrict = userDistrict['district']?.toString() ?? '';
            }

            // Set profile image URL by combining base URL with profile image path
            final profileImagePath = userData['user_profile_image'];
            if (profileImagePath != null && profileImagePath != 'None') {
              final baseUrl =
                  AppConfig.apiBaseUrl.split(
                    '/api',
                  )[0]; // Get the host URL part
              _existingProfileUrl = '$baseUrl$profileImagePath';
              print('Full Profile Image URL: $_existingProfileUrl');
            }
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load user data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dobController.text.isNotEmpty
              ? DateFormat('yyyy-MM-dd').parse(_dobController.text)
              : DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _updateProfile() async {
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
        throw Exception('No access token found');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/profile/update'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      });

      // Add text fields
      request.fields.addAll({
        'id': _userId ?? '',
        'name': _nameController.text,
        'user_dob': _dobController.text,
        'email': _emailController.text,
        'bar_registration_number': _barRegController.text,
        'address1': _address1Controller.text,
        'address2': _address2Controller.text,
        'address3': _address3Controller.text,
        'state': _selectedState ?? '',
        'district': _selectedDistrict ?? '',
        'state_id': _selectedStateId ?? '',
        'district_id': _selectedDistrictId ?? '',
        'user_district_pincode': _pinController.text,
      });

      // Add profile image if selected
      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            _profileImage!.path,
          ),
        );
      }

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Save updated data to SharedPreferences
        final responseJson = jsonDecode(responseData);
        await prefs.setString('user_name', _nameController.text);
        await prefs.setString('user_email', _emailController.text);
        await prefs.setString('user_dob', _dobController.text);
        await prefs.setString('bar_reg_number', _barRegController.text);
        await prefs.setString('address1', _address1Controller.text);
        await prefs.setString('address2', _address2Controller.text);
        await prefs.setString('address3', _address3Controller.text);
        await prefs.setString('state', _selectedState ?? '');
        await prefs.setString('district', _selectedDistrict ?? '');
        await prefs.setString('pin', _pinController.text);

        if (responseJson['profile_pic_url'] != null) {
          await prefs.setString(
            'profile_pic_url',
            responseJson['profile_pic_url'],
          );
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppConfig.isDevelopment
                ? 'Error: ${e.toString()}'
                : 'Failed to update profile. Please try again.',
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

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all stored preferences

      if (!mounted) return;

      // Navigate to login screen and clear all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to logout. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _logout();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        child:
                            _profileImage != null
                                ? ClipOval(
                                  child: Image.file(
                                    _profileImage!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : _existingProfileUrl != null
                                ? ClipOval(
                                  child: Image.network(
                                    _existingProfileUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.person, size: 50);
                                    },
                                  ),
                                )
                                : const Icon(Icons.person, size: 50),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18),
                            color: Colors.white,
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Basic Details Section
                const Text(
                  'Basic Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _dobController,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth *',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDate,
                    ),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your date of birth';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email ID *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Practicing Area Details Section
                const Text(
                  'Practicing Area Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _barRegController,
                  decoration: const InputDecoration(
                    labelText: 'Bar Registration Number *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your bar registration number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _address1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address 1 *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _address2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address 2',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _address3Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address 3',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // State dropdown with pre-selected value
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  decoration: const InputDecoration(
                    labelText: 'State *',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _states.map((String state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedState = newValue;
                      _selectedDistrict = null;
                      _selectedStateId =
                          newValue != null ? _stateIds[newValue] : null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your state';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // District dropdown with pre-selected value
                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: 'District *',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      (_selectedState != null &&
                              _districts.containsKey(_selectedState))
                          ? _districts[_selectedState]!.map((String district) {
                            return DropdownMenuItem<String>(
                              value: district,
                              child: Text(district),
                            );
                          }).toList()
                          : [],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDistrict = newValue;
                      _selectedDistrictId =
                          newValue != null ? _districtIds[newValue] : null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your district';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN Code *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter PIN code';
                    }
                    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                      return 'Please enter a valid 6-digit PIN code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Update Profile',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
