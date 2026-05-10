import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/api_exception.dart';
import 'package:project_mobile_pdam/core/utils/debug_log.dart';

class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    // Kalau tidak ada response (timeout, koneksi putus), lewatkan saja.
    if (response == null) {
      DebugLog.warning(
        message: '🌐 Tidak ada response dari server: ${err.message}',
      );
      handler.next(err);
      return;
    }

    final int status = response.statusCode ?? 0;
    final dynamic data = response.data;

    String message = _defaultMessageFor(status);
    Map<String, List<String>> fieldErrors = const {};

    if (data is Map) {
      final dynamic rawMessage = data['message'];
      if (rawMessage is String && rawMessage.isNotEmpty) {
        message = rawMessage;
      }

      // Body standar Laravel untuk 422.
      final dynamic rawErrors = data['errors'];
      if (rawErrors is Map) {
        fieldErrors = rawErrors.map<String, List<String>>((key, value) {
          final List<String> msgs = value is List
              ? value.map((e) => e.toString()).toList()
              : <String>[value.toString()];
          return MapEntry(key.toString(), msgs);
        });
      }
    } else if (data is String && data.isNotEmpty) {
      // Sebagian endpoint 500 mengembalikan string mentah.
      message = data;
    }

    // Sanitasi: untuk 404 backend kadang bocorkan nama model
    // (`No query results for model [App\Models\X]`). Ganti ke pesan
    // user-friendly supaya aman ditampilkan apa adanya di UI.
    if (status == 404 && message.contains('No query results')) {
      message = 'Data tidak ditemukan.';
    }

    final apiError = ApiException(
      statusCode: status,
      message: message,
      fieldErrors: fieldErrors,
    );

    DebugLog.warning(message: '⚠️ API error parsed: $apiError');

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: response,
        error: apiError,
        type: err.type,
        stackTrace: err.stackTrace,
      ),
    );
  }

  String _defaultMessageFor(int status) {
    switch (status) {
      case 401:
        return 'Sesi Anda berakhir. Silakan login kembali.';
      case 403:
        return 'Anda tidak punya akses untuk aksi ini.';
      case 404:
        return 'Data tidak ditemukan.';
      case 422:
        return 'Input tidak valid.';
      case 429:
        return 'Terlalu banyak permintaan. Coba lagi sebentar.';
      default:
        if (status >= 500) return 'Terjadi kesalahan di server.';
        return 'Terjadi kesalahan.';
    }
  }
}
