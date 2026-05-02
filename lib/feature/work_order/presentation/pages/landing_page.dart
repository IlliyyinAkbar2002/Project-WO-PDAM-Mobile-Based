import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/config/theme/app_color.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assignee_page/assignee_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assigner_page/assigner_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_masuk/assigner_page/assigner_work_order_masuk_page.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/extrawork/pengajuan_lembur.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/inventory/peminjaman_item_list.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/login.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/notifications.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/profile.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/profile_view_data.dart';

part 'widgets/_landing_page_header.dart';
part 'widgets/_landing_page_body.dart';
part 'widgets/_navigation_card.dart';
part 'widgets/_stats_card.dart';
part 'widgets/_role_selection_card.dart';
part 'widgets/_navigation_grid.dart';
part 'widgets/_navigation_list.dart';
part 'widgets/_attendance_card.dart';

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
                onPicIdChanged: (value) => null,
                onUserIdChanged: (value) => null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppColor get _colors => Theme.of(context).extension<AppColor>()!;
}
