import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/api_exception.dart';

/// Ubah error mentah dari layer data menjadi pesan siap tampil.
///
/// [ApiErrorInterceptor] sudah membungkus body error backend menjadi
/// [ApiException] dan menempelkannya di `DioException.error`, tapi memanggil
/// `toString()` pada [DioException] menghasilkan dump teknis sehingga pesan
/// aslinya terkubur. Helper ini membongkar lapisan tersebut.
///
/// Untuk [DioException] body response diprioritaskan karena Laravel mengirim
/// `{message, errors: {...}}` atau `{error: "..."}` — termasuk pesan 422 custom
/// yang memang ditulis untuk dibaca pengguna.
///
/// Logika ini disalin dari `WorkOrderBloc._friendlyErrorMessage`; salinan lain
/// masih hidup di `WorkOrderBloc` dan `LemburBloc` dan belum diarahkan ke sini
/// supaya diff tetap sempit — kandidat pembersihan berikutnya.
String friendlyApiErrorMessage(
  dynamic error, {
  String serverErrorFallback = 'Terjadi kesalahan di server. Silakan coba lagi.',
}) {
  if (error is DioException) {
    final apiError = error.error;
    if (apiError is ApiException) {
      return _safeApiErrorMessage(apiError, serverErrorFallback);
    }

    final data = error.response?.data;
    if (data is Map) {
      // Endpoint custom (mis. assign staff) memakai key `error` dan pesannya
      // sengaja ditulis untuk dibaca SPV — tampilkan apa adanya.
      final customError = data['error'];
      if (customError is String && customError.isNotEmpty) {
        return customError;
      }

      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
      final message = data['message'];
      if (message != null) return message.toString();
    }
    if (data is String && data.isNotEmpty) return data;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Koneksi ke server terlalu lama. Silakan coba lagi.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
    }
    return 'Terjadi kesalahan jaringan. Silakan coba lagi.';
  }

  if (error is ApiException) {
    return _safeApiErrorMessage(error, serverErrorFallback);
  }

  return error?.toString() ?? 'Terjadi kesalahan tidak diketahui.';
}

/// Menjaga UI dari pesan teknis backend saat status 5xx.
String _safeApiErrorMessage(ApiException error, String serverErrorFallback) {
  if (error.isServerError) return serverErrorFallback;

  final joined = error.allErrorsJoined();
  if (joined.isNotEmpty && joined != error.message) {
    return joined;
  }
  if (error.fieldErrors.isNotEmpty) {
    final parts = <String>[];
    error.fieldErrors.forEach((field, msgs) {
      parts.addAll(msgs);
    });
    if (parts.isNotEmpty) return parts.join('; ');
  }
  return error.message;
}
