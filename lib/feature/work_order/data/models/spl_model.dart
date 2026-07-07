import 'dart:convert';
import 'package:project_mobile_pdam/feature/work_order/data/models/status_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/user_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/spl_entity.dart';

class SplModel extends SplEntity {
  const SplModel({
    super.id,
    super.statusId,
    super.statusCode,
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
    // BE TARGET (MergerManual) mengirim `status` sebagai enum string
    // ('pending'|'approved'|'rejected'); skema lama mengirim objek status
    // ({id, nama}). Tangani keduanya agar parsing respons tidak crash.
    final dynamic rawStatus = map['status'];
    return SplModel(
      id: map['id'],
      statusId: map['status_id'],
      statusCode: rawStatus is String ? rawStatus : null,
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
      status: rawStatus is Map
          ? StatusModel.fromMap(Map<String, dynamic>.from(rawStatus))
          : null,
      pemohon: map['pemohon'] != null
          ? UserModel.fromMap(map['pemohon'])
          : null,
      members: map['members'],
    );
  }

  /// Body untuk PUT /v1/lembur-spl/{id} (verifikasi/approval lembur).
  /// Kontrak BE TARGET (MergerManual) HANYA membaca:
  ///   - `status` (WAJIB, enum 'pending'|'approved'|'rejected')
  ///   - `verifikator_id` (nullable, users.id approver)
  ///   - `alasan_ditolak` (nullable)
  /// BE MENGABAIKAN `status_id`/`decision`; mengirim `status_id` tanpa `status`
  /// menyebabkan 422 ("status field is required").
  Map<String, dynamic> toMap() {
    final payload = <String, dynamic>{
      'status': _resolveStatusEnum(),
      'verifikator_id': verificatorId,
      'alasan_ditolak': reason,
    };
    payload.removeWhere((key, value) => value == null);
    return payload;
  }

  /// Turunkan status enum BE: utamakan [statusCode]; fallback ke [statusId]
  /// (2→approved, 4→rejected) atau [decision] agar pemanggil lama (detail WO
  /// keluar/masuk) tetap mengirim `status` yang benar tanpa `status_id`.
  String? _resolveStatusEnum() {
    final code = statusCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    switch (statusId) {
      case 2:
        return 'approved';
      case 4:
        return 'rejected';
    }
    switch (decision) {
      case 'accept':
        return 'approved';
      case 'reject':
        return 'rejected';
    }
    return null;
  }

  SplEntity toEntity() {
    return SplEntity(
      id: id,
      statusId: statusId,
      statusCode: statusCode,
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
      statusCode: entity.statusCode,
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
