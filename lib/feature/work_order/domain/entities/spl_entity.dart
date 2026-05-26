import 'package:equatable/equatable.dart';
import 'status_entity.dart';
import 'user_entity.dart';

class SplEntity extends Equatable {
  final int? id;
  final int? statusId;
  final String? decision;
  final int? verificatorId;
  final DateTime? createdAt;
  final DateTime? verificationDate;
  final String? reason;
  final String? judulPekerjaan;
  final String? jenisPekerjaan;
  final DateTime? tanggalLembur;
  final String? jamMulai;
  final int? estimasiJam;
  final String? alasanLembur;
  final int? pemohonId;
  final StatusEntity? status;
  final UserEntity? pemohon;
  final List<dynamic>? members;

  const SplEntity({
    this.id,
    this.statusId,
    this.decision,
    this.verificatorId,
    this.createdAt,
    this.verificationDate,
    this.reason,
    this.judulPekerjaan,
    this.jenisPekerjaan,
    this.tanggalLembur,
    this.jamMulai,
    this.estimasiJam,
    this.alasanLembur,
    this.pemohonId,
    this.status,
    this.pemohon,
    this.members,
  });

  @override
  List<Object?> get props => [
        id,
        statusId,
        decision,
        verificatorId,
        createdAt,
        verificationDate,
        reason,
        judulPekerjaan,
        jenisPekerjaan,
        tanggalLembur,
        jamMulai,
        estimasiJam,
        alasanLembur,
        pemohonId,
        status,
        pemohon,
        members,
      ];

  SplEntity copyWith({
    int? id,
    int? statusId,
    String? decision,
    int? verificatorId,
    DateTime? createdAt,
    DateTime? verificationDate,
    String? reason,
    String? judulPekerjaan,
    String? jenisPekerjaan,
    DateTime? tanggalLembur,
    String? jamMulai,
    int? estimasiJam,
    String? alasanLembur,
    int? pemohonId,
    StatusEntity? status,
    UserEntity? pemohon,
    List<dynamic>? members,
  }) {
    return SplEntity(
      id: id ?? this.id,
      statusId: statusId ?? this.statusId,
      decision: decision ?? this.decision,
      verificatorId: verificatorId ?? this.verificatorId,
      createdAt: createdAt ?? this.createdAt,
      verificationDate: verificationDate ?? this.verificationDate,
      reason: reason ?? this.reason,
      judulPekerjaan: judulPekerjaan ?? this.judulPekerjaan,
      jenisPekerjaan: jenisPekerjaan ?? this.jenisPekerjaan,
      tanggalLembur: tanggalLembur ?? this.tanggalLembur,
      jamMulai: jamMulai ?? this.jamMulai,
      estimasiJam: estimasiJam ?? this.estimasiJam,
      alasanLembur: alasanLembur ?? this.alasanLembur,
      pemohonId: pemohonId ?? this.pemohonId,
      status: status ?? this.status,
      pemohon: pemohon ?? this.pemohon,
      members: members ?? this.members,
    );
  }
}
