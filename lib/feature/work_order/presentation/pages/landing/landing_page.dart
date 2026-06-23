import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/notification_bloc.dart';
import 'package:project_mobile_pdam/config/theme/app_color.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/assignee_page/assignee_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/assigner_page/assigner_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/assignment_wo/assigner_page/assigner_work_order_masuk_page.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/approval/persetujuan_peminjaman_barang.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/pengajuan_lembur/pengajuan_lembur.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/pengajuan_lembur/riwayat_pengajuan_lembur.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/inventory/peminjaman_item_list.dart';
import 'package:project_mobile_pdam/feature/auth/presentation/login.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/notifications.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/profile.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/profile_view_data.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/Report/list_laporan_workorder.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';

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

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends AppStatePage<LandingPage> {
  @override
  void initState() {
    super.initState();
    final user = AuthStorage.getUserSync();
    // Identitas daftar WO berbasis pegawai (assignment & assigned_to memakai
    // m_pegawai), bukan users.id. Lihat skema MergerManual.
    final pegawaiId = user?['pegawai_id'] as int?;

    final isSpv = AuthStorage.getJabatanKodeSync() == 'SPV';

    context.read<WorkOrderBloc>().add(
      GetWorkOrdersEvent(
        userId: isSpv ? null : pegawaiId,
        picId: isSpv ? pegawaiId : null,
      ),
    );
  }

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
