import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:project_mobile_pdam/config/theme/app_theme.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/login.dart';
import 'service_locator.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Try to load .env file, but don't fail if it doesn't exist
    try {
      await dotenv.load();
      print("✅ .env file loaded successfully");
      print("✅ Google Maps API Key: ${dotenv.env['GOOGLE_MAPS_API']}");
    } catch (e) {
      print("⚠️ .env file not found or couldn't be loaded, using defaults: $e");
      // No-op: AppConfig uses safe fallbacks when dotenv isn't initialized
    }

    // Initialize auth storage to load token from secure storage
    await AuthStorage.initialize();
    print("✅ Auth storage initialized");

    // Set up auth token getter for API calls (using synchronous getter)
    RemoteDatasource.setAuthTokenGetter(() => AuthStorage.getTokenSync());

    await di.init();
    print("🎉 Dependency berhasil diinisialisasi!");
  } catch (e, stacktrace) {
    print("❌ Gagal menginisialisasi dependency: $e");
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
      providers: [BlocProvider(create: (_) => di.sl<WorkOrderBloc>())],
      child: MaterialApp(
        theme: ThemeManager.theme,
        home: const LoginPage(),
        // home: const LandingPage(),
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
      ),
    );
  }
}
