/// User role for Role-Based Access Control.
enum UserRole {
  officer,
  supervisor,
  user,
}

/// Authenticated user model matching FastAPI UserResponse.
class UserModel {
  final String userId;
  final String? name;
  final String? email;
  final String? username;
  final UserRole role;
  final String? department;
  final String? profileImage;
  final bool isActive;

  const UserModel({
    required this.userId,
    this.name,
    this.email,
    this.username,
    required this.role,
    this.department,
    this.profileImage,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      username: json['username'] as String?,
      role: _parseRole(json['role'] as String?),
      department: json['department'] as String?,
      profileImage: json['profile_image'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static UserRole _parseRole(String? roleStr) {
    if (roleStr == null) return UserRole.user;
    final r = roleStr.toLowerCase();
    if (r == 'officer') return UserRole.officer;
    if (r == 'supervisor') return UserRole.supervisor;
    return UserRole.user;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'name': name,
      'email': email,
      'username': username,
      'role': role.name.toUpperCase(),
      'department': department,
      'profile_image': profileImage,
      'is_active': isActive,
    };
  }
}
