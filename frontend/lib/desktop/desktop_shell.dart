import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'breakpoints.dart';
import 'desktop_theme.dart';
import 'screens/desktop_dashboard_screen.dart';
import 'screens/desktop_employees_screen.dart';
import 'screens/desktop_profile_screen.dart';
import 'screens/desktop_tasks_screen.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key, required this.isManager});

  final bool isManager;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _index = 0;
  int _dataVersion = 0;

  List<_NavItem> get _navItems {
    if (widget.isManager) {
      return const [
        _NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
        _NavItem('Tasks', Icons.checklist_outlined, Icons.checklist),
        _NavItem('Employees', Icons.groups_outlined, Icons.groups),
        _NavItem('Profile', Icons.person_outline, Icons.person),
      ];
    }
    return const [
      _NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
      _NavItem('My Tasks', Icons.checklist_outlined, Icons.checklist),
      _NavItem('Profile', Icons.person_outline, Icons.person),
    ];
  }

  int get _profileIndex => _navItems.length - 1;

  void _selectNav(int index) {
    setState(() {
      _index = index;
      _dataVersion += 1;
    });
  }

  void _onDataChanged() {
    setState(() {
      _dataVersion += 1;
    });
  }

  List<Widget> _buildPages() {
    final dashboard = DesktopDashboardScreen(
      onViewAllTasks: () => _selectNav(1),
      refreshToken: _dataVersion,
    );
    final tasks = DesktopTasksScreen(
      refreshToken: _dataVersion,
      onDataChanged: _onDataChanged,
      isManager: widget.isManager,
    );
    final profile = const DesktopProfileScreen();

    if (widget.isManager) {
      return [
        dashboard,
        tasks,
        DesktopEmployeesScreen(
          refreshToken: _dataVersion,
          onDataChanged: _onDataChanged,
        ),
        profile,
      ];
    }
    return [dashboard, tasks, profile];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final collapsed = DesktopBreakpoints.isSidebarCollapsed(width);
    final pages = _buildPages();
    final safeIndex = _index.clamp(0, pages.length - 1);

    return Scaffold(
      backgroundColor: DesktopColors.background,
      body: Row(
        children: [
          _DesktopSidebar(
            collapsed: collapsed,
            selectedIndex: safeIndex,
            items: _navItems,
            onSelect: _selectNav,
          ),
          Expanded(
            child: Column(
              children: [
                _DesktopHeader(
                  onProfileTap: () => _selectNav(_profileIndex),
                ),
                Expanded(
                  child: IndexedStack(
                    index: safeIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.collapsed,
    required this.selectedIndex,
    required this.items,
    required this.onSelect,
  });

  final bool collapsed;
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    final initial = (user?.username.isNotEmpty ?? false)
        ? user!.username[0].toUpperCase()
        : '?';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: collapsed ? 76 : 240,
      decoration: const BoxDecoration(
        color: DesktopColors.card,
        border: Border(
          right: BorderSide(color: DesktopColors.border),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                collapsed ? 12 : 20,
                20,
                collapsed ? 12 : 20,
                24,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DesktopColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.task_alt,
                      color: DesktopColors.primary,
                      size: 20,
                    ),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Task Manager',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DesktopColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Tooltip(
                      message: collapsed ? item.label : '',
                      child: Material(
                        color: selected
                            ? DesktopColors.primarySoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => onSelect(index),
                          hoverColor: DesktopColors.primarySoft.withValues(
                            alpha: 0.55,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: collapsed ? 0 : 12,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: collapsed
                                  ? MainAxisAlignment.center
                                  : MainAxisAlignment.start,
                              children: [
                                Icon(
                                  selected ? item.selectedIcon : item.icon,
                                  size: 20,
                                  color: selected
                                      ? DesktopColors.primary
                                      : DesktopColors.textSecondary,
                                ),
                                if (!collapsed) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        color: selected
                                            ? DesktopColors.primary
                                            : DesktopColors.textPrimary,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                collapsed ? 10 : 16,
                12,
                collapsed ? 10 : 16,
                16,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: DesktopColors.border),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: DesktopColors.primary,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.username ?? 'User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DesktopColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            user?.roleLabel ?? 'Employee',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DesktopColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.onProfileTap});

  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    final initial = (user?.username.isNotEmpty ?? false)
        ? user!.username[0].toUpperCase()
        : '?';

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: DesktopColors.card,
        border: Border(
          bottom: BorderSide(color: DesktopColors.border),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: DesktopColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: DesktopColors.primarySoft,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: DesktopColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  user?.username ?? 'User',
                  style: const TextStyle(
                    color: DesktopColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: DesktopColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
