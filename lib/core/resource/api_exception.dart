/// Error kontrak baru pasca TKT-08.
///
/// Backend sekarang mengembalikan:
///   - **422** → `{message, errors: {field: [msg...]}}` (validator)
///   - **401** → `{message: "Unauthenticated."}`
///   - **403** → `{message: "This action is unauthorized."}`
///   - **404** → `{message: "No query results..."}`
///   - **429** → `{message: "Too Many Attempts."}`
///   - **500** → `{success: false, message: "..."}` (generic)
///
/// Lihat `Guide_mobile_flutter.md` bagian 7 untuk detail & contoh body.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, List<String>> fieldErrors;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.fieldErrors = const {},
  });

  bool get isValidation => statusCode == 422;
  bool get isUnauthenticated => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isTooManyRequests => statusCode == 429;
  bool get isServerError => statusCode >= 500;

  /// Pesan error pertama untuk field tertentu. Cocok untuk menampilkan
  /// inline error di `TextField.decoration.errorText`.
  String? errorFor(String field) {
    final list = fieldErrors[field];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  /// Gabungkan semua pesan error jadi satu string multi-baris, berguna
  /// untuk snackbar "ringkas kesalahan".
  String allErrorsJoined({String separator = '\n'}) {
    if (fieldErrors.isEmpty) return message;
    final parts = <String>[];
    fieldErrors.forEach((field, msgs) {
      for (final m in msgs) {
        parts.add(m);
      }
    });
    return parts.isEmpty ? message : parts.join(separator);
  }

  @override
  String toString() =>
      'ApiException($statusCode, $message, fieldErrors=$fieldErrors)';
}
