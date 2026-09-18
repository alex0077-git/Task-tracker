import '../models/app_user.dart';
import '../services/api_service.dart';

/// Shared profile fields for mobile and desktop profile screens.
class ProfileViewData {
  const ProfileViewData({
    required this.username,
    required this.roleLabel,
    required this.email,
    required this.initial,
  });

  final String username;
  final String roleLabel;
  final String email;
  final String initial;

  bool get hasEmail => email.isNotEmpty;

  factory ProfileViewData.fromCurrentUser() {
    return ProfileViewData.fromUser(ApiService.instance.currentUser);
  }

  factory ProfileViewData.fromUser(AppUser? user) {
    final username = user?.username ?? 'Unknown';
    return ProfileViewData(
      username: username,
      roleLabel: user?.roleLabel ?? 'Employee',
      email: user?.email ?? '',
      initial: avatarInitial(user?.username),
    );
  }
}

String avatarInitial(String? username) {
  if (username == null || username.isEmpty) {
    return '?';
  }
  return username[0].toUpperCase();
}
