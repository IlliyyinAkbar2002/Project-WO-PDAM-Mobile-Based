import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';

/// Entity untuk progress individual satu anggota tim.
///
/// Digunakan oleh SPV untuk melihat kontribusi masing-masing anggota.
class MemberProgressEntity extends Equatable {
  /// ID user anggota tim
  final int userId;

  /// Nama lengkap anggota
  final String nama;

  /// NIP anggota (opsional)
  final String? nip;

  /// Jabatan anggota (e.g., "Staff", "Senior Staff")
  final String jabatan;

  /// Apakah anggota ini adalah PIC (koordinator tim)
  final bool isPic;

  /// Total submissions yang sudah dilakukan anggota ini
  final int totalSubmissions;

  /// Submissions hari ini
  final int todaySubmissions;

  /// Sisa kuota anggota ini
  final int quotaRemaining;

  /// Total kuota anggota ini
  final int quotaTotal;

  /// List semua progress yang disubmit oleh anggota ini
  final List<WorkOrderProgressEntity> progressList;

  const MemberProgressEntity({
    required this.userId,
    required this.nama,
    this.nip,
    required this.jabatan,
    required this.isPic,
    required this.totalSubmissions,
    required this.todaySubmissions,
    required this.quotaRemaining,
    required this.quotaTotal,
    required this.progressList,
  });

  /// Hitung persentase progress anggota ini
  double get progressPercentage {
    if (quotaTotal == 0) return 0.0;
    return (totalSubmissions / quotaTotal) * 100;
  }

  @override
  List<Object?> get props => [
        userId,
        nama,
        nip,
        jabatan,
        isPic,
        totalSubmissions,
        todaySubmissions,
        quotaRemaining,
        quotaTotal,
        progressList,
      ];

  MemberProgressEntity copyWith({
    int? userId,
    String? nama,
    String? nip,
    String? jabatan,
    bool? isPic,
    int? totalSubmissions,
    int? todaySubmissions,
    int? quotaRemaining,
    int? quotaTotal,
    List<WorkOrderProgressEntity>? progressList,
  }) {
    return MemberProgressEntity(
      userId: userId ?? this.userId,
      nama: nama ?? this.nama,
      nip: nip ?? this.nip,
      jabatan: jabatan ?? this.jabatan,
      isPic: isPic ?? this.isPic,
      totalSubmissions: totalSubmissions ?? this.totalSubmissions,
      todaySubmissions: todaySubmissions ?? this.todaySubmissions,
      quotaRemaining: quotaRemaining ?? this.quotaRemaining,
      quotaTotal: quotaTotal ?? this.quotaTotal,
      progressList: progressList ?? this.progressList,
    );
  }
}
