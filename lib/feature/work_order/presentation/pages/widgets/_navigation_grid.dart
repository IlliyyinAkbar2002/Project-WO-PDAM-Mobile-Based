part of '../landing_page.dart';

class _NavigationGrid extends StatelessWidget {
  final int? selectedPicId;
  final int? selectedUserId;

  const _NavigationGrid({
    required this.selectedPicId,
    required this.selectedUserId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColor>()!;

    final items = [
      _NavigationItem(
        icon: Icons.calendar_month_outlined,
        label: 'Meeting Agenda',
        onTap: () {
          // picId tidak lagi diperlukan - backend menggunakan authenticated user untuk filter
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssignerWorkOrderPage(picId: selectedPicId),
            ),
          );
        },
      ),
      _NavigationItem(
        icon: Icons.check_circle_outline,
        label: 'Approval',
        onTap: () {
          // TODO: Navigate to approval page
        },
      ),
      _NavigationItem(
        icon: Icons.list_alt_outlined,
        label: 'Tasks',
        onTap: () {
          // Get user role to determine which bottom sheet to show
          final user = AuthStorage.getUserSync();
          final roleId = user?['role_id'] as int?;
          final positionId = user?['employee']?['position_id'] as int?;

          // Show role-specific tasks modal bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: false,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withOpacity(0.3),
            builder: (ctx) {
              // Manajer role (role_id: 2) - Show Manajer tasks
              if (roleId == 2 || (roleId == 3 && positionId == 4)) {
                return _TasksBottomSheetManajer(
                  onWorkOrderKeluar: () {
                    // picId tidak lagi diperlukan untuk filter - backend menggunakan authenticated user
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AssignerWorkOrderPage(picId: selectedPicId),
                      ),
                    );
                  },
                  onWorkOrderMasuk: () {
                    if (selectedUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please select User ID first'),
                          backgroundColor: colors.warning,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AssigneeWorkOrderPage(userId: selectedUserId!),
                      ),
                    );
                  },
                  onItSupport: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('IT Support coming soon'),
                        backgroundColor: colors.primary[600],
                      ),
                    );
                  },
                  onKuponEbbm: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Kupon E-BBM coming soon'),
                        backgroundColor: colors.primary[600],
                      ),
                    );
                  },
                  onSppd: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('SPPD coming soon'),
                        backgroundColor: colors.primary[600],
                      ),
                    );
                  },
                );
              }
              // Users role (role_id: 3) - Show Users tasks
              else {
                return _TasksBottomSheetUsers(
                  selectedUserId: selectedUserId,
                  positionId: positionId ?? 0,
                );
              }
            },
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          );
        },
      ),
      _NavigationItem(
        icon: Icons.people_outline,
        label: 'Attendance',
        onTap: () {
          // TODO: Navigate to attendance page
        },
      ),
      _NavigationItem(
        icon: Icons.receipt_long_outlined,
        label: 'Payslip',
        onTap: () {
          // TODO: Navigate to reports page
        },
      ),
      _NavigationItem(
        icon: Icons.home_outlined,
        label: 'Our Assets',
        onTap: () {
          // TODO: Navigate to settings page
        },
      ),
      _NavigationItem(
        icon: Icons.description_outlined,
        label: 'Document Request',
        onTap: () {
          // TODO: Navigate to help page
        },
      ),
      _NavigationItem(
        icon: Icons.more_horiz,
        label: 'More',
        onTap: () {
          // TODO: Show more options
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _NavigationGridItem(item: items[index]);
      },
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _NavigationGridItem extends StatelessWidget {
  final _NavigationItem item;

  const _NavigationGridItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE), // blue-100
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              item.icon,
              color: const Color(0xFF2563EB), // blue-600
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: const Color(0xFF374151), // gray-700
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet shown when Manajer taps on "Tasks" grid item
class _TasksBottomSheetManajer extends StatelessWidget {
  final VoidCallback onWorkOrderKeluar;
  final VoidCallback onWorkOrderMasuk;
  final VoidCallback onItSupport;
  final VoidCallback onKuponEbbm;
  final VoidCallback onSppd;

  const _TasksBottomSheetManajer({
    required this.onWorkOrderKeluar,
    required this.onWorkOrderMasuk,
    required this.onItSupport,
    required this.onKuponEbbm,
    required this.onSppd,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Grabber handle
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1), // gray-300
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  _TaskMenuItem(
                    label: 'Work Order Keluar',
                    onTap: onWorkOrderKeluar,
                  ),
                  _TaskMenuItem(
                    label: 'Work Order Masuk',
                    onTap: onWorkOrderMasuk,
                  ),
                  _TaskMenuItem(label: 'IT Support', onTap: onItSupport),
                  _TaskMenuItem(label: 'Kupon E-BBM', onTap: onKuponEbbm),
                  _TaskMenuItem(label: 'SPPD', onTap: onSppd),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskMenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TaskMenuItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF475569)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet shown when Users tap on "Tasks" grid item
class _TasksBottomSheetUsers extends StatelessWidget {
  final int? selectedUserId;
  final int? positionId;

  const _TasksBottomSheetUsers({
    required this.selectedUserId,
    required this.positionId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColor>()!;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Grabber handle
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1), // gray-300
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  _TaskMenuItem(
                    label: 'Jurnal',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Jurnal coming soon'),
                          backgroundColor: colors.primary[600],
                        ),
                      );
                    },
                  ),
                  _TaskMenuItem(
                    label: 'Work Order',
                    onTap: () {
                      // Ambil userId dari AuthStorage untuk staff
                      final user = AuthStorage.getUserSync();
                      final userId = user?['id'] as int?;

                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('User ID tidak ditemukan'),
                            backgroundColor: colors.warning,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AssigneeWorkOrderPage(userId: userId),
                        ),
                      );
                    },
                  ),
                  _TaskMenuItem(
                    label: 'IT Support',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('IT Support coming soon'),
                          backgroundColor: colors.primary[600],
                        ),
                      );
                    },
                  ),
                  _TaskMenuItem(
                    label: 'Kupon E-BBM',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Kupon E-BBM coming soon'),
                          backgroundColor: colors.primary[600],
                        ),
                      );
                    },
                  ),
                  _TaskMenuItem(
                    label: 'SPPD',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('SPPD coming soon'),
                          backgroundColor: colors.primary[600],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
