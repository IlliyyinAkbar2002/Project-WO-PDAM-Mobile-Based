part of '../landing_page.dart';

class _LandingPageHeader extends StatelessWidget {
  const _LandingPageHeader();

  String _getEmployeeName() {
    final user = AuthStorage.getUserSync();
    return user?['employee']?['name'] ?? 'Unknown User';
  }

  String _getEmployeeId() {
    final user = AuthStorage.getUserSync();
    return user?['employee']?['employee_id'] ?? '';
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
              color: Theme.of(dialogContext).extension<AppColor>()!.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await AuthStorage.clearAuth();
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xffff574d),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  String _getRoleName() {
    final user = AuthStorage.getUserSync();
    final roleId = user?['role_id'];

    if (roleId == 2) return 'Supervisor';
    if (roleId == 3) return 'Staff';
    return 'User';
  }

  Future<void> _showProfileMenu(
    BuildContext context,
    GlobalKey profileKey,
  ) async {
    final colors = Theme.of(context).extension<AppColor>()!;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final profileBox = profileKey.currentContext?.findRenderObject() as RenderBox?;
    final profilePosition = profileBox?.localToGlobal(Offset.zero, ancestor: overlay) ?? Offset.zero;
    final profileSize = profileBox?.size ?? const Size(64, 64);

    await showGeneralDialog(
      context: context,
      barrierLabel: 'profile_menu',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) {
        return Stack(
          children: [
            Positioned(
              top: profilePosition.dy + profileSize.height + 10,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.background[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProfileActionItem(
                        icon: Icons.person_outline,
                        label: 'View Profile',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          final profileData =
                              ProfileViewDataResolver.resolveOrDefault();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProfilePage.safe(data: profileData),
                            ),
                          );
                        },
                      ),
                      _ProfileActionItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings page belum tersedia.'),
                            ),
                          );
                        },
                      ),
                      _ProfileActionItem(
                        icon: Icons.notifications_none_outlined,
                        label: 'Notifications',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsPage(),
                            ),
                          );
                        },
                      ),
                      _ProfileActionItem(
                        icon: Icons.logout,
                        label: 'Logout',
                        iconColor: const Color(0xffff4354),
                        textColor: const Color(0xffff4354),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _handleLogout(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColor>()!;
    final textTheme = Theme.of(context).textTheme;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final profileAvatarKey = GlobalKey();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 24 + statusBarHeight, 24, 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary[500]!, colors.primary[700]!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PDAM Surya Sembada',
                      style: textTheme.titleLarge?.copyWith(
                        color: colors.background[100],
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getEmployeeName(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.background[100]!.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_getEmployeeId().isNotEmpty)
                      Text(
                        _getEmployeeId(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.background[100]!.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _getRoleName(),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.background[100]!.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Logout Button - matching Figma design
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xffff574d),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _handleLogout(context),
                          borderRadius: BorderRadius.circular(9999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 3.5,
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  GestureDetector(
                    key: profileAvatarKey,
                    onTap: () => _showProfileMenu(context, profileAvatarKey),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colors.background[100]!.withOpacity(0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: colors.primary[300],
                            child: Icon(
                              Icons.person,
                              size: 36,
                              color: colors.background[100],
                            ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xffff574d),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.primary[500]!,
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.notifications,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _ProfileActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColor>()!;
    final iconResultColor = iconColor ?? colors.foreground[700];
    final textResultColor = textColor ?? colors.foreground[700];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconResultColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textResultColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
