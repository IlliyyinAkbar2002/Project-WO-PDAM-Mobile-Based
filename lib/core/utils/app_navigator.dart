import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/feature/auth/presentation/login.dart';

/// Navigator global agar kode di luar widget tree (mis. Dio interceptor)
/// bisa memindahkan halaman tanpa butuh `BuildContext`.
class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static void resetToLogin() {
    final nav = key.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
