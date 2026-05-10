import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/config/app_config.dart';
import 'package:project_mobile_pdam/config/theme/app_theme.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_bloc.dart';
import 'package:project_mobile_pdam/feature/auth/presentation/login.dart';
import 'service/service_locator.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppConfig.init();
    print("✅ AppConfig loaded — BACKEND_DOMAIN: ${AppConfig.backendDomain}");

    await AuthStorage.initialize();
    print("✅ Auth storage initialized");

    RemoteDatasource.setAuthTokenGetter(() => AuthStorage.getTokenSync());

    await di.init();
    print("🎉 Dependency berhasil diinisialisasi!");
  } catch (e, stacktrace) {
    print("❌ Gagal menginisialisasi: $e");
    print(stacktrace);
  }

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends AppStatePage<App> {
  @override
  Widget buildPage(BuildContext context) {
    AppSnackbar.setTheme(ThemeManager.theme);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<WorkOrderBloc>()),
        BlocProvider(create: (_) => di.sl<MaterialBloc>()),
      ],
      child: MaterialApp(
        theme: ThemeManager.theme,
        home: const LoginPage(),
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
      ),
    );
  }
}
