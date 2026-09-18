class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    this.email = '',
    this.isStaff = false,
    this.isActive = true,
    this.role = 'employee',
  });

  final int id;
  final String username;
  final String email;
  final bool isStaff;
  final bool isActive;
  final String role;

  bool get isManager => isStaff || role == 'admin';

  String get roleLabel => isManager ? 'Admin / Manager' : 'Employee';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String? ?? '',
      isStaff: json['is_staff'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      role: json['role'] as String? ?? 'employee',
    );
  }
}
