/// User role for Role-Based Access Control.
enum UserRole {
  officer,
  supervisor,
  admin,
}

/// Authenticated user model.
class UserModel {
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final String badgeNumber;
  final String? avatarUrl;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.badgeNumber,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.officer,
      ),
      badgeNumber: json['badge_number'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'role': role.name,
      'badge_number': badgeNumber,
      'avatar_url': avatarUrl,
    };
  }

  /// Display-friendly role label.
  String get roleLabel {
    switch (role) {
      case UserRole.officer:
        return 'Field Officer';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}
