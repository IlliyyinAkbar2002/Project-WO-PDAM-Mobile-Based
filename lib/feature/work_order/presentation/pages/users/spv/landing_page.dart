import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/landing/landing_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';

class SpvLandingPage extends StatefulWidget {
  const SpvLandingPage({super.key});

  @override
  State<SpvLandingPage> createState() => _SpvLandingPageState();
}

class _SpvLandingPageState extends AppStatePage<SpvLandingPage> {
  @override
  void initState() {
    super.initState();
    final user = AuthStorage.getUserSync();
    final pegawaiId = user?['pegawai_id'] as int?;
    context.read<WorkOrderBloc>().add(
      GetWorkOrdersEvent(assignedToPegawaiId: pegawaiId),
    );
  }
  @override
  Widget buildPage(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LandingPageHeaderWidget(),
                const SizedBox(height: 16),

                // Work Orders / Stats Card
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: LandingPageStatsCard(),
                ),
                const SizedBox(height: 16),

                // Attendance Card
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: LandingPageAttendanceCard(),
                ),
                const SizedBox(height: 16),

                // Navigation Grid
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: LandingPageNavigationGrid(
                    selectedPicId: null,
                    selectedUserId: null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
