import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:project_mobile_pdam/config/app_config.dart';
import 'package:project_mobile_pdam/config/theme/app_theme.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_bloc.dart';
import 'package:project_mobile_pdam/feature/auth/presentation/login.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/journal_draft_cubit.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/spv/landing_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/staff/landing_page.dart';
import 'service/service_locator.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('id_ID', null);

    await AppConfig.init();

    await AuthStorage.initialize();

    RemoteDatasource.setAuthTokenGetter(() => AuthStorage.getTokenSync());

    await di.init();
  } catch (e, stacktrace) {
    debugPrint('Error during initialization: $e');
    debugPrint('Stacktrace: $stacktrace');
  }

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends AppStatePage<App> {
  Widget _getInitialPage() {
    // Check if user has a valid session
    if (!AuthStorage.isLoggedIn()) {
      return const LoginPage();
    }

    // Get user data to determine role-based landing page
    final user = AuthStorage.getUserSync();
    if (user == null) {
      return const LoginPage();
    }

    final roleId = user['role_id'] as int?;
    final jabatanKode = AuthStorage.getJabatanKodeSync();

    debugPrint('🔄 Restoring session for role: $roleId, jabatan: $jabatanKode');


    if (roleId == 3) {
      if (jabatanKode == 'SPV') {
        return const SpvLandingPage();
      } else {
        return const StaffLandingPage();
      }
    }

    // Role selain employee (staff/spv) belum didukung, kembali ke login
    AuthStorage.clearAuth();
    return const LoginPage();
  }

  @override
  Widget buildPage(BuildContext context) {
    AppSnackbar.setTheme(ThemeManager.theme);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<WorkOrderBloc>()),
        BlocProvider(create: (_) => di.sl<MaterialBloc>()),
        BlocProvider(create: (_) => di.sl<JournalDraftCubit>()),
      ],
      child: MaterialApp(
        theme: ThemeManager.theme,
        home: _getInitialPage(),
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
      ),
    );
  }
}
