class UserModel {
  final String uid;
  final String email;
  final String username;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      role: map['role'] ?? 'karyawan',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'role': role,
      'createdAt': createdAt,
    };
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isSupervisor => role.toLowerCase() == 'supervisor';
  bool get isKaryawan => role.toLowerCase() == 'karyawan';
}