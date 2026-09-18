import 'package:flutter/material.dart';

import '../../screens/role_home.dart';
import '../../shared/profile_view_data.dart';
import '../desktop_theme.dart';

class DesktopProfileScreen extends StatelessWidget {
  const DesktopProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ProfileViewData.fromCurrentUser();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              color: DesktopColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your account details for this Task Manager session.',
            style: TextStyle(
              color: DesktopColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DesktopColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DesktopColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: DesktopColors.primarySoft,
                        child: Text(
                          profile.initial,
                          style: const TextStyle(
                            color: DesktopColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.username,
                              style: const TextStyle(
                                color: DesktopColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              profile.roleLabel,
                              style: const TextStyle(
                                color: DesktopColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: DesktopColors.border),
                  const SizedBox(height: 20),
                  _InfoRow(
                    label: 'Username',
                    value: profile.username,
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Email',
                    value: profile.hasEmail ? profile.email : '—',
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Role',
                    value: profile.roleLabel,
                  ),
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => logoutToLogin(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesktopColors.danger,
                        side: const BorderSide(color: DesktopColors.danger),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Log out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: DesktopColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: DesktopColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
