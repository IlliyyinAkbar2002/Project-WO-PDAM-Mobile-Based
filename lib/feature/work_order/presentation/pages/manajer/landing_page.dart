import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/config/theme/app_color.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/landing_page.dart'
    as admin;

class ManajerLandingPage extends StatefulWidget {
  const ManajerLandingPage({super.key});

  @override
  State<ManajerLandingPage> createState() => _ManajerLandingPageState();
}

class _ManajerLandingPageState extends AppStatePage<ManajerLandingPage> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors.background[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const admin.LandingPageHeaderWidget(),
              const SizedBox(height: 8),

              // Stats Card Section
              Transform.translate(
                offset: const Offset(0, -28),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: admin.LandingPageStatsCard(),
                ),
              ),
              const SizedBox(height: 24),

              // Attendance Card Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: admin.LandingPageAttendanceCard(),
              ),
              const SizedBox(height: 24),

              // Quick Access Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Access',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _colors.foreground[900],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const admin.LandingPageNavigationGrid(
                      selectedPicId: null,
                      selectedUserId: null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  AppColor get _colors => Theme.of(context).extension<AppColor>()!;
}
