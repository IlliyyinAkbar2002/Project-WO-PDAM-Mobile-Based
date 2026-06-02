import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_quota_entity.dart';

class ProgressQuotaModel extends ProgressQuotaEntity {
  const ProgressQuotaModel({
    required super.workorderId,
    required super.userId,
    required super.sisaKuotaHariIni,
    required super.sisaKuotaTotal,
    required super.totalKuotaHariIni,
    required super.totalKuotaKeseluruhan,
    required super.sudahSubmitHariIni,
    required super.sudahSubmitTotal,
    required super.estimasiHari,
    required super.bisaCancel,
  });

  factory ProgressQuotaModel.fromJson(String source) =>
      ProgressQuotaModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory ProgressQuotaModel.fromMap(Map<String, dynamic> map) {
    debugPrint("📊 Parsing ProgressQuota: $map");

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    List<int> parseIntList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => parseInt(e))
            .whereType<int>()
            .toList();
      }
      return [];
    }

    return ProgressQuotaModel(
      workorderId: parseInt(map['workorder_id']) ?? 0,
      userId: parseInt(map['user_id']) ?? 0,
      sisaKuotaHariIni: parseInt(map['sisa_kuota_hari_ini']) ?? 0,
      sisaKuotaTotal: parseInt(map['sisa_kuota_total']) ?? 0,
      totalKuotaHariIni: parseInt(map['total_kuota_hari_ini']) ?? 8,
      totalKuotaKeseluruhan: parseInt(map['total_kuota_keseluruhan']) ?? 0,
      sudahSubmitHariIni: parseInt(map['sudah_submit_hari_ini']) ?? 0,
      sudahSubmitTotal: parseInt(map['sudah_submit_total']) ?? 0,
      estimasiHari: parseInt(map['estimasi_hari']) ?? 0,
      bisaCancel: parseIntList(map['bisa_cancel']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workorder_id': workorderId,
      'user_id': userId,
      'sisa_kuota_hari_ini': sisaKuotaHariIni,
      'sisa_kuota_total': sisaKuotaTotal,
      'total_kuota_hari_ini': totalKuotaHariIni,
      'total_kuota_keseluruhan': totalKuotaKeseluruhan,
      'sudah_submit_hari_ini': sudahSubmitHariIni,
      'sudah_submit_total': sudahSubmitTotal,
      'estimasi_hari': estimasiHari,
      'bisa_cancel': bisaCancel,
    };
  }

  ProgressQuotaEntity toEntity() {
    return ProgressQuotaEntity(
      workorderId: workorderId,
      userId: userId,
      sisaKuotaHariIni: sisaKuotaHariIni,
      sisaKuotaTotal: sisaKuotaTotal,
      totalKuotaHariIni: totalKuotaHariIni,
      totalKuotaKeseluruhan: totalKuotaKeseluruhan,
      sudahSubmitHariIni: sudahSubmitHariIni,
      sudahSubmitTotal: sudahSubmitTotal,
      estimasiHari: estimasiHari,
      bisaCancel: bisaCancel,
    );
  }

  factory ProgressQuotaModel.fromEntity(ProgressQuotaEntity entity) {
    return ProgressQuotaModel(
      workorderId: entity.workorderId,
      userId: entity.userId,
      sisaKuotaHariIni: entity.sisaKuotaHariIni,
      sisaKuotaTotal: entity.sisaKuotaTotal,
      totalKuotaHariIni: entity.totalKuotaHariIni,
      totalKuotaKeseluruhan: entity.totalKuotaKeseluruhan,
      sudahSubmitHariIni: entity.sudahSubmitHariIni,
      sudahSubmitTotal: entity.sudahSubmitTotal,
      estimasiHari: entity.estimasiHari,
      bisaCancel: entity.bisaCancel,
    );
  }
}
