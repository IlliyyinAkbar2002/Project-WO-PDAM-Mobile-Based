/// Konstanta untuk master data Work Order.
///
/// Nilai id di sini **harus** selaras dengan seeder backend (lihat
/// migration TKT-02 / TKT-03). Id dipaksa eksplisit lewat seeder, jadi
/// aman dipakai sebagai sumber kebenaran di sisi Flutter.
///
/// Mengikuti kontrak yang dijelaskan di `Guide_mobile_flutter.md`
/// (TKT-01..TKT-08).
class TipeProgressId {
  static const int mulai = 1;
  static const int progress = 2;
  static const int selesai = 3;

  static const String kodeMulai = 'MULAI';
  static const String kodeProgress = 'PROGRESS';
  static const String kodeSelesai = 'SELESAI';

  static bool isMulai(int? id) => id == mulai;
  static bool isProgress(int? id) => id == progress;
  static bool isSelesai(int? id) => id == selesai;

  /// Label human-readable untuk UI Flutter. `order` dipakai untuk
  /// membentuk label "Progress N" (N = order+1) bagi progress antara.
  /// Nilai default memang "Mulai"/"Selesai" agar kompatibel dengan
  /// komponen UI lama yang masih bergantung pada string literal.
  static String label(int? id, {int? order}) {
    switch (id) {
      case mulai:
        return 'Mulai';
      case selesai:
        return 'Selesai';
      case progress:
        if (order != null) return 'Progress ${order > 0 ? order : order + 1}';
        return 'Progress';
      default:
        return '-';
    }
  }

  /// Konversi kode string dari backend (mis. relasi `tipeProgress.kode`)
  /// ke id numerik konstan di atas. Berguna jika suatu saat backend
  /// mulai eager-load relasi `tipeProgress`.
  static int? fromKode(String? kode) {
    switch (kode?.toUpperCase()) {
      case kodeMulai:
        return mulai;
      case kodeProgress:
        return progress;
      case kodeSelesai:
        return selesai;
      default:
        return null;
    }
  }
}

/// Mirror tabel `m_status` untuk baris progres (DRAFT/SUBMITTED/VERIFIED).
/// Nilai `id` di sini default mengikuti seeder backend (TKT-03). Jika
/// id di backend berbeda, cukup ubah di sini — tidak perlu menyebar
/// ke banyak file UI.
class ProgressStatusId {
  static const int draft = 9;
  static const int submitted = 10;
  static const int verified = 11;

  static bool isDraft(int? id) => id == draft;
  static bool isSubmitted(int? id) => id == submitted;
  static bool isVerified(int? id) => id == verified;
}

/// Kode master action dari TKT-01 (stabil, tidak tergantung id numerik).
/// Nilainya match dengan kolom `m_action.kode`.
class WorkOrderActionKode {
  static const String penugasan = 'PENUGASAN';
  static const String freeze = 'FREEZE';
  static const String resume = 'RESUME';
  static const String extend = 'EXTEND';
}
