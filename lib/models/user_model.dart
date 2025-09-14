// lib/models/user_model.dart
class User {
  final String id;
  final String name;
  final String email;
  final String employeeId;
  final String role;
  final String department;
  final String? userClass;
  final String? section;
  final String? profileImage;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.role,
    required this.department,
    this.userClass,
    this.section,
    this.profileImage,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      employeeId: json['employeeId'] ?? '',
      role: json['role'] ?? '',
      department: json['department'] ?? '',
      userClass: json['class'],
      section: json['section'],
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'employeeId': employeeId,
      'role': role,
      'department': department,
      'class': userClass,
      'section': section,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
