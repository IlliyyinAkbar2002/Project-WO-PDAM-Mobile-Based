class TipeProgressId {
  static const int mulai = 1;
  static const int progress = 2;
  static const int selesai = 3;
  static const int inspeksi = 6;

  static const String kodeMulai = 'MULAI';
  static const String kodeProgress = 'PROGRESS';
  static const String kodeSelesai = 'SELESAI';
  static const String kodeInspeksi = 'INSPEKSI';

  static bool isMulai(int? id) => id == mulai;
  static bool isProgress(int? id) => id == progress;
  static bool isSelesai(int? id) => id == selesai;
  static bool isInspeksi(int? id) => id == inspeksi;

  static String label(int? id, {int? order}) {
    switch (id) {
      case mulai:
        return 'Mulai';
      case inspeksi:
        return 'Inspeksi';
      case selesai:
        return 'Selesai';
      case progress:
        if (order != null) return 'Progress ${order > 0 ? order : order + 1}';
        return 'Progress';
      default:
        return '-';
    }
  }

  static int? fromKode(String? kode) {
    switch (kode?.toUpperCase()) {
      case kodeMulai:
        return mulai;
      case kodeInspeksi:
        return inspeksi;
      case kodeProgress:
        return progress;
      case kodeSelesai:
        return selesai;
      default:
        return null;
    }
  }
}

/// Tahapan pengerjaan WO (1-4) — selaras dengan TahapanWorkorder di backend.
/// 1 Persiapan, 2 Pengerjaan, 3 Pengujian, 4 Dokumentasi.
class TahapanWorkorder {
  static const int persiapan = 1;
  static const int pengerjaan = 2;
  static const int pengujian = 3;
  static const int dokumentasi = 4;

  /// Tahap maksimum yang dapat dilaporkan lewat mode "Progress" (Laporan).
  /// Tahap 4 (Dokumentasi) hanya boleh lewat mode "Selesai".
  static const int maxProgress = pengujian;
}

class ProgressStatusId {
  static const int draft = 9;
  static const int submitted = 10;
  static const int verified = 11;
  static const int revisiRequested = 14; // Status when SPV rejects progress
  static const int dibatalkan = 18;

  static bool isDraft(int? id) => id == draft;
  static bool isSubmitted(int? id) => id == submitted;
  static bool isVerified(int? id) => id == verified;
  static bool isRevisiRequested(int? id) => id == revisiRequested;
  static bool isDibatalkan(int? id) => id == dibatalkan;
}

/// Kode master action dari TKT-01 (stabil, tidak tergantung id numerik).
/// Nilainya match dengan kolom `m_action.kode`.
class WorkOrderActionKode {
  static const String penugasan = 'PENUGASAN';
  static const String freeze = 'FREEZE';
  static const String resume = 'RESUME';
  static const String extend = 'EXTEND';
}

class WorkOrderStatusId {
  static const int pengecekan = 5;
  static const int selesai = 6;
  static const int inProgress = 7;

  static const int ditugaskanKeSpv = 12;
  static const int ditugaskanKeStaff = 13;
  static const int menungguApprovalManager = 16;
  static const int ditolakManager = 17;
}

class WorkOrderListFilterTypeId {
  static const int infrastruktur = 1;
  static const int jaringan = 2;
  static const int meter = 3;
}

/// Kategori form WO — sesuai m_jenis_workorder.kategori_form di backend.
/// Digunakan untuk menentukan form apa yang ditampilkan SPV saat assign staff.
class WoKategoriForm {
  static const String meter = 'meter';
  static const String jaringan = 'jaringan';
  static const String infrastruktur = 'infrastruktur';

  /// Label UI untuk setiap kategori
  static String label(String? kategori) {
    switch (kategori) {
      case meter:
        return 'WO Meter';
      case jaringan:
        return 'WO Jaringan';
      case infrastruktur:
        return 'WO Infrastruktur';
      default:
        return 'Work Order';
    }
  }

  /// Semua kategori yang tersedia
  static const List<String> all = [meter, jaringan, infrastruktur];
}
