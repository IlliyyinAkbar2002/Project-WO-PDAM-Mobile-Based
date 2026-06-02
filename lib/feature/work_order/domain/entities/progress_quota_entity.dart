import 'package:equatable/equatable.dart';

/// Entity untuk kuota progress individual user.
///
/// Sebelumnya kuota berbasis tim (satu tim berbagi kuota).
/// Sekarang setiap anggota tim punya kuota sendiri.
class ProgressQuotaEntity extends Equatable {
  /// ID work order
  final int workorderId;

  /// ID user yang sedang login (NEW: individual tracking)
  final int userId;

  /// Sisa kuota hari ini untuk user ini
  final int sisaKuotaHariIni;

  /// Sisa kuota total untuk user ini
  final int sisaKuotaTotal;

  /// Total kuota per hari (biasanya 8)
  final int totalKuotaHariIni;

  /// Total kuota keseluruhan (estimasi_hari × 8)
  final int totalKuotaKeseluruhan;

  /// Jumlah yang sudah disubmit hari ini oleh user ini
  final int sudahSubmitHariIni;

  /// Total yang sudah disubmit oleh user ini
  final int sudahSubmitTotal;

  /// Estimasi hari pengerjaan work order
  final int estimasiHari;

  /// List ID progress yang bisa di-cancel oleh user ini
  final List<int> bisaCancel;

  const ProgressQuotaEntity({
    required this.workorderId,
    required this.userId,
    required this.sisaKuotaHariIni,
    required this.sisaKuotaTotal,
    required this.totalKuotaHariIni,
    required this.totalKuotaKeseluruhan,
    required this.sudahSubmitHariIni,
    required this.sudahSubmitTotal,
    required this.estimasiHari,
    required this.bisaCancel,
  });

  @override
  List<Object?> get props => [
        workorderId,
        userId,
        sisaKuotaHariIni,
        sisaKuotaTotal,
        totalKuotaHariIni,
        totalKuotaKeseluruhan,
        sudahSubmitHariIni,
        sudahSubmitTotal,
        estimasiHari,
        bisaCancel,
      ];

  ProgressQuotaEntity copyWith({
    int? workorderId,
    int? userId,
    int? sisaKuotaHariIni,
    int? sisaKuotaTotal,
    int? totalKuotaHariIni,
    int? totalKuotaKeseluruhan,
    int? sudahSubmitHariIni,
    int? sudahSubmitTotal,
    int? estimasiHari,
    List<int>? bisaCancel,
  }) {
    return ProgressQuotaEntity(
      workorderId: workorderId ?? this.workorderId,
      userId: userId ?? this.userId,
      sisaKuotaHariIni: sisaKuotaHariIni ?? this.sisaKuotaHariIni,
      sisaKuotaTotal: sisaKuotaTotal ?? this.sisaKuotaTotal,
      totalKuotaHariIni: totalKuotaHariIni ?? this.totalKuotaHariIni,
      totalKuotaKeseluruhan:
          totalKuotaKeseluruhan ?? this.totalKuotaKeseluruhan,
      sudahSubmitHariIni: sudahSubmitHariIni ?? this.sudahSubmitHariIni,
      sudahSubmitTotal: sudahSubmitTotal ?? this.sudahSubmitTotal,
      estimasiHari: estimasiHari ?? this.estimasiHari,
      bisaCancel: bisaCancel ?? this.bisaCancel,
    );
  }
}
