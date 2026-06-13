import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/member_progress_entity.dart';

/// Entity untuk response endpoint `/by-member/{workorderId}`.
///
/// Berisi daftar semua anggota tim beserta progress individual mereka.
/// Digunakan oleh SPV untuk monitoring progress per anggota.
class ProgressByMemberEntity extends Equatable {
  /// ID work order
  final int workorderId;

  /// Nama work order
  final String workorderName;

  /// Estimasi hari pengerjaan
  final int estimasiHari;

  /// List semua anggota tim dengan progress masing-masing
  final List<MemberProgressEntity> members;

  const ProgressByMemberEntity({
    required this.workorderId,
    required this.workorderName,
    required this.estimasiHari,
    required this.members,
  });

  /// Cari PIC dari list anggota
  MemberProgressEntity? get pic {
    try {
      return members.firstWhere((member) => member.isPic);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        workorderId,
        workorderName,
        estimasiHari,
        members,
      ];

  ProgressByMemberEntity copyWith({
    int? workorderId,
    String? workorderName,
    int? estimasiHari,
    List<MemberProgressEntity>? members,
  }) {
    return ProgressByMemberEntity(
      workorderId: workorderId ?? this.workorderId,
      workorderName: workorderName ?? this.workorderName,
      estimasiHari: estimasiHari ?? this.estimasiHari,
      members: members ?? this.members,
    );
  }
}
