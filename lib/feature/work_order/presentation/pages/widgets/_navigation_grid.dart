part of '../landing/landing_page.dart';

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
      // _NavigationItem(
      //   icon: Icons.calendar_month_outlined,
      //   label: 'Meeting Agenda',
      //   onTap: () {
      //     // picId tidak lagi diperlukan - backend menggunakan authenticated user untuk filter
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => AssignerWorkOrderPage(picId: selectedPicId),
      //       ),
      //     );
      //   },
      // ),
      _NavigationItem(
        icon: Icons.check_circle_outline,
        label: 'Approval',
        onTap: () {
          // final user = AuthStorage.getUserSync();
          final isSpv = AuthStorage.getJabatanKodeSync() == 'SPV';
          // final isManajer = user?['role_id'] == 2;

          if (!isSpv) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Approval hanya tersedia untuk Supervisor'),
                backgroundColor: colors.warning,
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PersetujuanPeminjamanBarangPage(),
            ),
          );
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
          final isSpv = AuthStorage.getJabatanKodeSync() == 'SPV';

          // Show role-specific tasks modal bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: false,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withValues(alpha: 0.3),
            builder: (ctx) {
              // Manajer (role_id: 2) and SPV share the same tasks sheet
              if (roleId == 2 || isSpv) {
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
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AssignerWorkOrderMasukPage(picId: selectedPicId),
                      ),
                    );
                  },
                  // onItSupport: () {
                  //   Navigator.pop(ctx);
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(
                  //       content: const Text('IT Support coming soon'),
                  //       backgroundColor: colors.primary[600],
                  //     ),
                  //   );
                  // },
                  // onKuponEbbm: () {
                  //   Navigator.pop(ctx);
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(
                  //       content: const Text('Kupon E-BBM coming soon'),
                  //       backgroundColor: colors.primary[600],
                  //     ),
                  //   );
                  // },
                  // onSppd: () {
                  //   Navigator.pop(ctx);
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(
                  //       content: const Text('SPPD coming soon'),
                  //       backgroundColor: colors.primary[600],
                  //     ),
                  //   );
                  // },
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
      // _NavigationItem(
      //   icon: Icons.people_outline,
      //   label: 'Attendance',
      //   onTap: () {
      //     // TODO: Navigate to attendance page
      //   },
      // ),
      _NavigationItem(
        icon: Icons.receipt_long_outlined,
        label: 'Report',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ListLaporanWorkorderPage(),
            ),
          );
        },
      ),
      _NavigationItem(
        icon: Icons.home_outlined,
        label: 'Our Assets',
        onTap: () {
          final user = AuthStorage.getUserSync();
          final roleId = user?['role_id'] as int?;
          if (roleId != 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Our Assets hanya tersedia untuk Staff/SPV',
                ),
                backgroundColor: colors.warning,
              ),
            );
            return;
          }
          final isSpv = AuthStorage.getJabatanKodeSync() == 'SPV';

          showModalBottomSheet(
            context: context,
            isScrollControlled: false,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withValues(alpha: 0.3),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            builder: (ctx) {
              if (isSpv) {
                return _OurAssetsBottomSheet(
                  title: 'Melihat stok barang',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PeminjamanItemListPage(),
                      ),
                    );
                  },
                );
              }

              return _OurAssetsBottomSheet(
                title: 'Melihat stok barang',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PeminjamanItemListPage(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      _NavigationItem(
        icon: Icons.description_outlined,
        label: 'Pengajuan Lembur',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PengajuanLemburPage()),
          );
        },
      ),
      // _NavigationItem(
      //   icon: Icons.more_horiz,
      //   label: 'More',
      //   onTap: () {
      //     // TODO: Show more options
      //   },
      // ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.69,
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

    const navy = Color(0xFF0B2A6B);
    const tileBg = Color(0xFFEAF1FF);
    const tileBorder = Color(0x99DBEAFE); // rgba(219,234,254,0.6)
    const iconColor = Color(0xFF2E7BFF);

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: tileBg,
                border: Border.all(color: tileBorder, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: iconColor, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: navy,
                fontWeight: FontWeight.w500,
                height: 1.25,
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
  // final VoidCallback onItSupport;
  // final VoidCallback onKuponEbbm;
  // final VoidCallback onSppd;

  const _TasksBottomSheetManajer({
    required this.onWorkOrderKeluar,
    required this.onWorkOrderMasuk,
    // required this.onItSupport,
    // required this.onKuponEbbm,
    // required this.onSppd,
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
              color: Colors.black.withValues(alpha: 0.08),
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
                  // _TaskMenuItem(label: 'IT Support', onTap: onItSupport),
                  // _TaskMenuItem(label: 'Kupon E-BBM', onTap: onKuponEbbm),
                  // _TaskMenuItem(label: 'SPPD', onTap: onSppd),
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

class _OurAssetsBottomSheet extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _OurAssetsBottomSheet({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.35,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(color: const Color(0xFFC7C7C7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0x4D3C3C43),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              _OurAssetsMenuItem(label: title, onTap: onTap),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OurAssetsMenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OurAssetsMenuItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC7C7C7)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1A1D21),
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
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
              color: Colors.black.withValues(alpha: 0.08),
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
                  // _TaskMenuItem(
                  //   label: 'Jurnal',
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       SnackBar(
                  //         content: const Text('Jurnal coming soon'),
                  //         backgroundColor: colors.primary[600],
                  //       ),
                  //     );
                  //   },
                  // ),
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
                  // _TaskMenuItem(
                  //   label: 'IT Support',
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       SnackBar(
                  //         content: const Text('IT Support coming soon'),
                  //         backgroundColor: colors.primary[600],
                  //       ),
                  //     );
                  //   },
                  // ),
                  // _TaskMenuItem(
                  //   label: 'Kupon E-BBM',
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       SnackBar(
                  //         content: const Text('Kupon E-BBM coming soon'),
                  //         backgroundColor: colors.primary[600],
                  //       ),
                  //     );
                  //   },
                  // ),
                  // _TaskMenuItem(
                  //   label: 'SPPD',
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       SnackBar(
                  //         content: const Text('SPPD coming soon'),
                  //         backgroundColor: colors.primary[600],
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
