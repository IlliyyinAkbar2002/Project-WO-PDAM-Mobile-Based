part of '../landing/landing_page.dart';

class _LandingPageHeader extends StatelessWidget {
  const _LandingPageHeader();

  String _getEmployeeName() {
    final user = AuthStorage.getUserSync();
    return (user?['employee']?['name'] ?? user?['name'] ?? 'Unknown User')
        .toString();
  }

  String _getEmployeeId() {
    final user = AuthStorage.getUserSync();
    return (user?['employee']?['employee_id'] ?? '').toString();
  }

  String _getRoleLabel() {
    final user = AuthStorage.getUserSync() ?? <String, dynamic>{};
    return ProfileViewDataResolver.resolvePositionLabel(user);
  }

  /// Ambil 1-2 huruf inisial dari nama untuk avatar.
  String _getInitials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    final first = parts.first.characters.firstOrNull ?? '';
    final last = parts.last.characters.firstOrNull ?? '';
    return '$first$last'.toUpperCase();
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final dangerColor = Theme.of(
          dialogContext,
        ).extension<AppColor>()!.danger;
        return AlertDialog(
          title: Text(
            'Logout',
            style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
              color: dangerColor,
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
                debugPrint(
                  '🚪 User logged out from landing page, session cleared',
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;
                // Clear entire navigation stack and go to login
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(foregroundColor: dangerColor),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showProfileMenu(
    BuildContext context,
    GlobalKey profileKey,
  ) async {
    final colors = Theme.of(context).extension<AppColor>()!;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final profileBox =
        profileKey.currentContext?.findRenderObject() as RenderBox?;
    final profilePosition =
        profileBox?.localToGlobal(Offset.zero, ancestor: overlay) ??
        Offset.zero;
    final profileSize = profileBox?.size ?? const Size(56, 56);

    await showGeneralDialog(
      context: context,
      barrierLabel: 'profile_menu',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) {
        return Stack(
          children: [
            Positioned(
              top: profilePosition.dy + profileSize.height + 10,
              left: profilePosition.dx,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.background[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
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
                              builder: (_) =>
                                  ProfilePage.safe(data: profileData),
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
                        onTap: () async {
                          Navigator.of(dialogContext).pop();
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsPage(),
                            ),
                          );
                          if (context.mounted) {
                            final user = AuthStorage.getUserSync();
                            final userId = user?['id'] as int?;
                            final isSpv =
                                AuthStorage.getJabatanKodeSync() == 'SPV';
                            context.read<WorkOrderBloc>().add(
                              GetWorkOrdersEvent(
                                userId: isSpv ? null : userId,
                                picId: isSpv ? userId : null,
                              ),
                            );
                          }
                        },
                      ),
                      _ProfileActionItem(
                        icon: Icons.logout,
                        label: 'Logout',
                        iconColor: colors.danger,
                        textColor: colors.danger,
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
    final textTheme = Theme.of(context).textTheme;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final profileAvatarKey = GlobalKey();

    final name = _getEmployeeName();
    final employeeId = _getEmployeeId();
    final role = _getRoleLabel();
    final initials = _getInitials(name);

    // Warna spesifik dari Figma yang tidak ada di token AppColor.
    const headerNavy = Color(0xFF0B2A6B);
    const headerNavyTop = Color(0xFF112F73);
    const onlineGreen = Color(0xFF00D492);
    const roleBadgeYellow = Color(0xFFFFF4B8);
    const logoutRed = Color(0xFFE63946);
    const notifRed = Color(0xFFE63946);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, statusBarHeight + 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [headerNavyTop, headerNavy],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A1C398E),
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: avatar + nama/role/ID + notifikasi
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                key: profileAvatarKey,
                onTap: () => _showProfileMenu(context, profileAvatarKey),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2E7BFF), Color(0xFF0B2A6B)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: onlineGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: headerNavy, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: -0.4,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleBadgeYellow,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: headerNavy,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.55,
                              height: 1.5,
                            ),
                          ),
                        ),
                        if (employeeId.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'ID · $employeeId',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _NotificationButton(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                  if (context.mounted) {
                    final user = AuthStorage.getUserSync();
                    final userId = user?['id'] as int?;
                    final isSpv = AuthStorage.getJabatanKodeSync() == 'SPV';
                    context.read<WorkOrderBloc>().add(
                      GetWorkOrdersEvent(
                        userId: isSpv ? null : userId,
                        picId: isSpv ? userId : null,
                      ),
                    );
                  }
                },
                badgeColor: notifRed,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Baris bawah: salam + tombol logout
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Have a productive day',
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _LogoutPillButton(
                color: logoutRed,
                onTap: () => _handleLogout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color badgeColor;

  const _NotificationButton({required this.onTap, required this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  final bool showBadge =
                      state is NotificationLoaded && state.unreadCount > 0;
                  if (!showBadge) return const SizedBox();
                  return Positioned(
                    top: 8,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutPillButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _LogoutPillButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(999),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
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
