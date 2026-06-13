import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/member_progress_entity.dart';

class MemberProgressModel extends MemberProgressEntity {
  const MemberProgressModel({
    required super.userId,
    required super.nama,
    super.nip,
    required super.jabatan,
    required super.isPic,
    required super.progressList,
    super.tahapanTertinggi,
    super.progressTahapan,
  });

  factory MemberProgressModel.fromJson(String source) =>
      MemberProgressModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory MemberProgressModel.fromMap(Map<String, dynamic> map) {
    debugPrint("👤 Parsing MemberProgress: ${map['nama']}");

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }
      return false;
    }

    List<WorkOrderProgressModel> parseProgressList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map(
              (json) => WorkOrderProgressModel.fromMap(
                Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      }
      return [];
    }

    return MemberProgressModel(
      userId: parseInt(map['user_id']) ?? 0,
      nama: map['nama']?.toString() ?? '',
      nip: map['nip']?.toString(),
      jabatan: map['jabatan']?.toString() ?? '',
      isPic: parseBool(map['is_pic']),
      progressList: parseProgressList(map['progress_list']),
      tahapanTertinggi: parseInt(map['tahapan_tertinggi']),
      progressTahapan: parseInt(map['progress_tahapan']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'nama': nama,
      'nip': nip,
      'jabatan': jabatan,
      'is_pic': isPic,
      'progress_list': progressList
          .map(
            (progress) => WorkOrderProgressModel.fromEntity(progress).toMap(),
          )
          .toList(),
      'tahapan_tertinggi': tahapanTertinggi,
      'progress_tahapan': progressTahapan,
    };
  }

  MemberProgressEntity toEntity() {
    return MemberProgressEntity(
      userId: userId,
      nama: nama,
      nip: nip,
      jabatan: jabatan,
      isPic: isPic,
      progressList: progressList,
      tahapanTertinggi: tahapanTertinggi,
      progressTahapan: progressTahapan,
    );
  }

  factory MemberProgressModel.fromEntity(MemberProgressEntity entity) {
    return MemberProgressModel(
      userId: entity.userId,
      nama: entity.nama,
      nip: entity.nip,
      jabatan: entity.jabatan,
      isPic: entity.isPic,
      progressList: entity.progressList,
      tahapanTertinggi: entity.tahapanTertinggi,
      progressTahapan: entity.progressTahapan,
    );
  }
}
