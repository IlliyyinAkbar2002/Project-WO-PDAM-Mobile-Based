import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/notification_bloc.dart';
import 'package:project_mobile_pdam/config/theme/app_color.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assignee_page/assignee_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assigner_page/assigner_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_masuk/assigner_page/assigner_work_order_masuk_page.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/approval/persetujuan_peminjaman_barang.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/extrawork/pengajuan_lembur.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/inventory/peminjaman_item_list.dart';
import 'package:project_mobile_pdam/feature/auth/presentation/login.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/notifications.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/profile.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/profile_view_data.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/Report/list_laporan_workorder.dart';

part '../widgets/_landing_page_header.dart';
part '../widgets/_landing_page_body.dart';
part '../widgets/_navigation_card.dart';
part '../widgets/_stats_card.dart';
part '../widgets/_role_selection_card.dart';
part '../widgets/_navigation_grid.dart';
part '../widgets/_navigation_list.dart';
part '../widgets/_attendance_card.dart';

// Expose the header widget for other landing pages to use
class LandingPageHeaderWidget extends StatelessWidget {
  const LandingPageHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LandingPageHeader();
  }
}

// Expose the navigation grid for other landing pages to use
class LandingPageNavigationGrid extends StatelessWidget {
  final int? selectedPicId;
  final int? selectedUserId;

  const LandingPageNavigationGrid({
    super.key,
    this.selectedPicId,
    this.selectedUserId,
  });

  @override
  Widget build(BuildContext context) {
    return _NavigationGrid(
      selectedPicId: selectedPicId,
      selectedUserId: selectedUserId,
    );
  }
}

// Expose the stats card for other landing pages to use
class LandingPageStatsCard extends StatelessWidget {
  const LandingPageStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _StatsCard();
  }
}

// Expose the attendance card for other landing pages to use
class LandingPageAttendanceCard extends StatelessWidget {
  const LandingPageAttendanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AttendanceCard();
  }
}

// Expose the navigation list for users role landing pages
class LandingPageNavigationList extends StatelessWidget {
  final int? selectedPicId;
  final int? selectedUserId;

  const LandingPageNavigationList({
    super.key,
    this.selectedPicId,
    this.selectedUserId,
  });

  @override
  Widget build(BuildContext context) {
    return _NavigationList(
      selectedPicId: selectedPicId,
      selectedUserId: selectedUserId,
    );
  }
}

class LandingPageQuickAccessHeader extends StatelessWidget {
  final String roleTitle;
  final VoidCallback? onViewAll;

  const LandingPageQuickAccessHeader({
    super.key,
    required this.roleTitle,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const navy = Color(0xFF0B2A6B);
    const muted = Color(0xFF90A1B9);
    const linkColor = Color(0xFF2E7BFF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUICK ACCESS',
                  style: textTheme.labelSmall?.copyWith(
                    color: muted,
                    fontSize: 11,
                    letterSpacing: 1.54,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleTitle,
                  style: textTheme.titleLarge?.copyWith(
                    color: navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (onViewAll != null)
            InkWell(
              onTap: onViewAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'View all',
                  style: textTheme.bodySmall?.copyWith(
                    color: linkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends AppStatePage<LandingPage> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors.background[100],
      body: SafeArea(
        child: Column(
          children: [
            const _LandingPageHeader(),
            Expanded(
              child: _LandingPageBody(
                selectedPicId: null,
                selectedUserId: null,
                onPicIdChanged: (value) {},
                onUserIdChanged: (value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppColor get _colors => Theme.of(context).extension<AppColor>()!;
}
