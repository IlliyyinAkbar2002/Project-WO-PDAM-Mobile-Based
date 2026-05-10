import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final colors = Theme.of(context).extension<AppColor>()!;

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
                const admin.LandingPageHeaderWidget(),
                const SizedBox(height: 16),

                // Work Orders / Stats Card
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: admin.LandingPageStatsCard(),
                ),
                const SizedBox(height: 16),

                // Attendance Card
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: admin.LandingPageAttendanceCard(),
                ),
                const SizedBox(height: 24),

                // Quick Access section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      admin.LandingPageQuickAccessHeader(
                        roleTitle: 'Manager',
                        onViewAll: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Daftar lengkap menu belum tersedia.',
                              ),
                              backgroundColor: colors.primary[600],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      const admin.LandingPageNavigationGrid(
                        selectedPicId: null,
                        selectedUserId: null,
                      ),
                    ],
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
