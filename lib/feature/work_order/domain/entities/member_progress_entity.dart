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

  /// List semua progress yang disubmit oleh anggota ini
  final List<WorkOrderProgressEntity> progressList;
  final int? tahapanTertinggi;
  final int? progressTahapan;

  const MemberProgressEntity({
    required this.userId,
    required this.nama,
    this.nip,
    required this.jabatan,
    required this.isPic,
    required this.totalSubmissions,
    required this.todaySubmissions,
    required this.progressList,
    this.tahapanTertinggi,
    this.progressTahapan,
  });

  @override
  List<Object?> get props => [
    userId,
    nama,
    nip,
    jabatan,
    isPic,
    totalSubmissions,
    todaySubmissions,

    progressList,
    tahapanTertinggi,
    progressTahapan,
  ];

  MemberProgressEntity copyWith({
    int? userId,
    String? nama,
    String? nip,
    String? jabatan,
    bool? isPic,
    int? totalSubmissions,
    int? todaySubmissions,
    List<WorkOrderProgressEntity>? progressList,
    int? tahapanTertinggi,
    int? progressTahapan,
  }) {
    return MemberProgressEntity(
      userId: userId ?? this.userId,
      nama: nama ?? this.nama,
      nip: nip ?? this.nip,
      jabatan: jabatan ?? this.jabatan,
      isPic: isPic ?? this.isPic,
      totalSubmissions: totalSubmissions ?? this.totalSubmissions,
      todaySubmissions: todaySubmissions ?? this.todaySubmissions,
      progressList: progressList ?? this.progressList,
      tahapanTertinggi: tahapanTertinggi ?? this.tahapanTertinggi,
      progressTahapan: progressTahapan ?? this.progressTahapan,
    );
  }
}
