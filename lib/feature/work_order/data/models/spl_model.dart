import 'dart:convert';
import 'package:project_mobile_pdam/feature/work_order/data/models/status_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/user_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/spl_entity.dart';

class SplModel extends SplEntity {
  const SplModel({
    super.id,
    super.statusId,
    super.decision,
    super.verificatorId,
    super.createdAt,
    super.verificationDate,
    super.reason,
    super.judulPekerjaan,
    super.jenisPekerjaan,
    super.tanggalLembur,
    super.jamMulai,
    super.estimasiJam,
    super.alasanLembur,
    super.pemohonId,
    super.status,
    super.pemohon,
    super.members,
  });

  factory SplModel.fromJson(String source) =>
      SplModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory SplModel.fromMap(Map<String, dynamic> map) {
    return SplModel(
      id: map['id'],
      statusId: map['status_id'],
      decision: map['decision']?.toString(),
      verificatorId: map['verifikator_id'],
      createdAt: map['waktu_pengajuan'] != null
          ? DateTime.parse(map['waktu_pengajuan'])
          : null,
      verificationDate: map['waktu_verifikasi'] != null
          ? DateTime.parse(map['waktu_verifikasi'])
          : null,
      reason: map['alasan_ditolak'],
      judulPekerjaan: map['judul_pekerjaan'],
      jenisPekerjaan: map['jenis_pekerjaan'],
      tanggalLembur: map['tanggal_lembur'] != null
          ? DateTime.parse(map['tanggal_lembur'])
          : null,
      jamMulai: map['jam_mulai'],
      estimasiJam: map['estimasi_jam'],
      alasanLembur: map['alasan_lembur'],
      pemohonId: map['pemohon_id'],
      status: map['status'] != null
          ? StatusModel.fromMap(map['status'])
          : null,
      pemohon: map['pemohon'] != null
          ? UserModel.fromMap(map['pemohon'])
          : null,
      members: map['members'],
    );
  }

  Map<String, dynamic> toMap() {
    final payload = {
      'status_id': statusId,
      if (decision != null) 'decision': decision,
      'verifikator_id': verificatorId,
      // 'waktu_verifikasi': verificationDate?.toIso8601String(),
      'alasan_ditolak': reason,
      'judul_pekerjaan': judulPekerjaan,
      'jenis_pekerjaan': jenisPekerjaan,
      'tanggal_lembur': tanggalLembur != null
          ? '${tanggalLembur!.year.toString().padLeft(4, '0')}-${tanggalLembur!.month.toString().padLeft(2, '0')}-${tanggalLembur!.day.toString().padLeft(2, '0')}'
          : null,
      'jam_mulai': jamMulai,
      'estimasi_jam': estimasiJam,
      'alasan_lembur': alasanLembur,
      'pemohon_id': pemohonId,
    };
    payload.removeWhere((key, value) => value == null);
    return payload;
  }

  SplEntity toEntity() {
    return SplEntity(
      id: id,
      statusId: statusId,
      decision: decision,
      verificatorId: verificatorId,
      createdAt: createdAt,
      verificationDate: verificationDate,
      reason: reason,
      judulPekerjaan: judulPekerjaan,
      jenisPekerjaan: jenisPekerjaan,
      tanggalLembur: tanggalLembur,
      jamMulai: jamMulai,
      estimasiJam: estimasiJam,
      alasanLembur: alasanLembur,
      pemohonId: pemohonId,
      status: status,
      pemohon: pemohon,
      members: members,
    );
  }

  factory SplModel.fromEntity(SplEntity entity) {
    return SplModel(
      id: entity.id,
      statusId: entity.statusId,
      decision: entity.decision,
      verificatorId: entity.verificatorId,
      createdAt: entity.createdAt,
      verificationDate: entity.verificationDate,
      reason: entity.reason,
      judulPekerjaan: entity.judulPekerjaan,
      jenisPekerjaan: entity.jenisPekerjaan,
      tanggalLembur: entity.tanggalLembur,
      jamMulai: entity.jamMulai,
      estimasiJam: entity.estimasiJam,
      alasanLembur: entity.alasanLembur,
      pemohonId: entity.pemohonId,
      status: entity.status,
      pemohon: entity.pemohon,
      members: entity.members,
    );
  }
}
