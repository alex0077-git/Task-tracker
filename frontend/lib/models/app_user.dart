class AppUser {
  const AppUser({required this.id, required this.username});

  final int id;
  final String username;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      username: json['username'] as String,
    );
  }
}
