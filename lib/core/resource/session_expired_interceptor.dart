import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/utils/app_navigator.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';

/// Kalau backend membalas 401 di tengah sesi yang sedang aktif (mis. token
/// direvoke karena akun yang sama login lagi dari client lain), interceptor
/// ini otomatis membersihkan sesi lokal dan melempar user ke [LoginPage] —
/// tanpa perlu `BuildContext` dari pemanggil yang gagal.
///
/// 401 dari endpoint auth publik (login/register/dst) sengaja dikecualikan
/// karena di situ 401 berarti "salah password", bukan "sesi berakhir".
///
/// Harus didaftarkan SEBELUM [ApiErrorInterceptor]: `ErrorInterceptorHandler`
/// tidak punya varian reject yang meneruskan ke interceptor berikutnya, jadi
/// `handler.reject(...)` di ApiErrorInterceptor akan langsung memutus rantai
/// error dan melewati interceptor lain yang didaftarkan setelahnya. Karena
/// itu cek di sini pakai status code mentah, bukan `ApiException` hasil parse.
class SessionExpiredInterceptor extends Interceptor {
  static bool _isHandling = false;

  static const _excludedPaths = [
    '/v1/auth/login',
    '/v1/auth/register',
    '/v1/auth/check-email',
    '/v1/auth/new-password',
  ];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final path = err.requestOptions.path;

    final is401 = err.response?.statusCode == 401;
    final isExcluded = _excludedPaths.any((p) => path.contains(p));

    if (is401 && !isExcluded && !_isHandling) {
      _isHandling = true;
      _handleSessionExpired();
    }

    handler.next(err);
  }

  Future<void> _handleSessionExpired() async {
    await AuthStorage.clearAuth();
    AppNavigator.resetToLogin();
    AppSnackbar.showWarning('Sesi Anda berakhir. Silakan login kembali.');
    await Future.delayed(const Duration(seconds: 2));
    _isHandling = false;
  }
}
