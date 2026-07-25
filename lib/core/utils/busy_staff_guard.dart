import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';

/// Pre-kondisi assign staff: petugas yang masih memegang WO belum selesai
/// tidak boleh ditugaskan ke WO lain.
///
/// Aturan "sibuk" ditentukan backend dan dikirim lewat `is_busy` pada
/// `/v1/pegawai/filter` (bebas hanya bila WO penahannya berstatus `Selesai`
/// atau WO dinonaktifkan). Helper ini murni membaca flag tersebut — jangan
/// menduplikasi aturannya di sini, agar FE dan BE tidak bisa berbeda pendapat.
///
/// Sifatnya hard block: tidak ada jalur override, dan WO prioritas `Urgent`
/// tidak dikecualikan.
class BusyStaffGuard {
  const BusyStaffGuard._();

  /// Petugas terpilih yang sedang sibuk, urut sesuai urutan [selected].
  static List<UserEntity> busyAmong(Iterable<UserEntity> selected) {
    return selected.where((user) => user.isBusy).toList();
  }

  /// `null` bila seluruh [selected] bebas — artinya submit boleh lanjut.
  /// Selain itu, pesan siap tampil yang menyebut nama petugas beserta WO
  /// penahannya, karena SPV perlu tahu WO mana yang harus diselesaikan dulu.
  static String? validationMessage(Iterable<UserEntity> selected) {
    final busy = busyAmong(selected);
    if (busy.isEmpty) return null;

    final details = busy.map(_describe).join(', ');
    final subject = busy.length == 1 ? 'Petugas' : 'Petugas berikut';
    return '$subject masih memiliki WO yang belum selesai: $details. '
        'Selesaikan WO tersebut lebih dulu.';
  }

  static String _describe(UserEntity user) {
    final name = user.employee?.name ?? user.email ?? 'Petugas #${user.id}';
    final workorder = user.busyWorkorderName?.trim();
    if (workorder == null || workorder.isEmpty) return name;
    return '$name ($workorder)';
  }
}
