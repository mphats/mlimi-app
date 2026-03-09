class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final bool isActive;
  final DateTime? dateJoined;
  final String? profileImageUrl;
  final String? coverImageUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.isActive = true,
    this.dateJoined,
    this.profileImageUrl,
    this.coverImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      // Safely parse the id with improved type checking
      int id = 0;
      final idValue = json['id'];
      if (idValue is int) {
        id = idValue;
      } else if (idValue is String) {
        id = int.tryParse(idValue) ?? 0;
      }

      // Safely parse other fields with null-aware operators and type checking
      final username = json['username'] is String ? json['username'] : 'unknown_user';
      final email = json['email'] is String ? json['email'] : '';
      final role = json['role'] is String ? json['role'] : 'FARMER';
      final firstName = json['first_name'] is String ? json['first_name'] : null;
      final lastName = json['last_name'] is String ? json['last_name'] : null;
      final isActive = json['is_active'] is bool ? json['is_active'] : true;
      
      DateTime? dateJoined;
      if (json['date_joined'] is String) {
        try {
          dateJoined = DateTime.parse(json['date_joined']);
        } catch (e) {
          // If parsing fails, leave as null
          dateJoined = null;
        }
      }
      
      // Safely parse image URLs
      final profileImageUrl = json['profile_image'] is String ? json['profile_image'] : null;
      final coverImageUrl = json['cover_image'] is String ? json['cover_image'] : null;

      return UserModel(
        id: id,
        username: username,
        email: email,
        role: role,
        firstName: firstName,
        lastName: lastName,
        isActive: isActive,
        dateJoined: dateJoined,
        profileImageUrl: profileImageUrl,
        coverImageUrl: coverImageUrl,
      );
    } catch (e) {
      // Log the error for debugging purposes
      // In production, you might want to use a proper logging solution
      // print('Error parsing UserModel: $e');
      
      // Return a default UserModel if parsing fails
      return UserModel(
        id: 0,
        username: 'unknown_user',
        email: '',
        role: 'FARMER',
        isActive: false,
        dateJoined: null,
        profileImageUrl: null,
        coverImageUrl: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'is_active': isActive,
      'date_joined': dateJoined?.toIso8601String(),
      'profile_image': profileImageUrl,
      'cover_image': coverImageUrl,
    };
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  String get initials {
    if (firstName != null &&
        lastName != null &&
        firstName!.isNotEmpty &&
        lastName!.isNotEmpty) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    // Handle empty or very short username case
    if (username.isEmpty) {
      return 'UU'; // Unknown User
    }
    if (username.length == 1) {
      return username.toUpperCase();
    }
    return username.length >= 2
        ? username.substring(0, 2).toUpperCase()
        : username.toUpperCase();
  }

  String get roleDisplayName {
    switch (role) {
      case 'FARMER':
        return 'Farmer';
      case 'TRADER':
        return 'Trader';
      case 'AGRONOMIST':
        return 'Agronomist';
      case 'ADMIN':
        return 'Admin';
      default:
        return role;
    }
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? role,
    String? firstName,
    String? lastName,
    bool? isActive,
    DateTime? dateJoined,
    String? profileImageUrl,
    String? coverImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isActive: isActive ?? this.isActive,
      dateJoined: dateJoined ?? this.dateJoined,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, role: $role)';
  }
}