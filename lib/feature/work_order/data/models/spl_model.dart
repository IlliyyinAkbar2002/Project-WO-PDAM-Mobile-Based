import 'dart:convert';

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
    );
  }

  Map<String, dynamic> toMap() {
    final payload = {
      'status_id': statusId,
      if (decision != null) 'decision': decision,
      'verifikator_id': verificatorId,
      // 'waktu_verifikasi': verificationDate?.toIso8601String(),
      'alasan_ditolak': reason,
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
    );
  }
}
