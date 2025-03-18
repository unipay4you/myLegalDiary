class User {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;

  User({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  // Convert User object to a Map for API
  Map<String, dynamic> toMap() {
    return {
      'user_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'password': password, // Note: In a real app, this should be hashed
    };
  }

  // Create a User object from a Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      fullName: map['user_name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      password: map['password'] ?? '',
    );
  }

  // Create a copy of the User with optional new values
  User copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? password,
  }) {
    return User(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
    );
  }
}
