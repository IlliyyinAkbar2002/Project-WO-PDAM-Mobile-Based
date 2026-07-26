import 'package:project_mobile_pdam/core/auth/mobile_access.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';

/// Penilaian jabatan untuk KANDIDAT petugas (hasil `/v1/pegawai/filter`),
/// bukan untuk user yang sedang login — untuk itu pakai
/// `AuthStorage.getJabatanKodeSync()`.
///
/// Aturan wawancara: koordinator/PIC berada di atas staff biasa atau setara
/// Staff Senior. Aturan itu sebelumnya ditulis ulang sebagai literal string di
/// beberapa tempat (`jabatan == 'staff senior'`); extension ini menjadikannya
/// satu sumber kebenaran dan menormalkan lewat [JabatanKode] yang sama dengan
/// gerbang login, sehingga variasi penulisan dari backend ("Staff Senior",
/// "STAFF SENIOR", atau hanya `jabatan_id`) tetap terbaca konsisten.
extension UserJabatan on UserEntity {
  /// Kode jabatan terkanonisasi ([JabatanKode]), atau `null` bila backend tidak
  /// mengirim nama maupun id jabatan.
  String? get jabatanKode => JabatanKode.fromEmployee(
    nama: employee?.jabatan,
    id: employee?.jabatanId,
  );

  /// `true` hanya untuk jabatan Staff Senior — syarat menjadi koordinator/PIC.
  bool get isStaffSenior => jabatanKode == JabatanKode.seniorStaff;

  /// `true` untuk Staff maupun Staff Senior: jabatan yang boleh menjadi
  /// anggota tim pelaksana di lapangan.
  bool get isPelaksanaLapangan {
    final kode = jabatanKode;
    return kode == JabatanKode.staff || kode == JabatanKode.seniorStaff;
  }

  /// Nama tampilan yang aman dipakai di pesan validasi.
  String get displayName =>
      employee?.name ?? email ?? 'Petugas #${id ?? '-'}';
}
