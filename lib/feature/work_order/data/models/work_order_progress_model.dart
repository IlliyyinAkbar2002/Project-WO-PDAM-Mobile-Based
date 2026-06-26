import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/documentation_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/progress_detail_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';

class WorkOrderProgressModel extends WorkOrderProgressEntity {
  final List<XFile>? photos;
  final List<ProgressDetailModel>? progressDetails;
  final String? reviewAction;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  const WorkOrderProgressModel({
    super.id,
    super.order,
    super.workOrderId,
    super.tipeProgressId,
    super.statusId,
    super.submittedByUserId,
    super.description,
    super.documentation,
    super.submitTime,
    super.createdAt,
    super.updatedAt,
    this.progressDetails,
    this.photos,
    this.reviewAction,
    this.latitude,
    this.longitude,
    this.accuracy,
    super.kategoriData,
    super.tahapan,
  });

  factory WorkOrderProgressModel.fromJson(String source) =>
      WorkOrderProgressModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory WorkOrderProgressModel.fromMap(Map<String, dynamic> map) {
    debugPrint("📢 Parsing Progress: $map");

    DateTime? parseUtcDateTime(dynamic value) {
      if (value is DateTime) return value.isUtc ? value.toLocal() : value;
      if (value is String) {
        String raw = value.trim();
        if (raw.isEmpty) return null;
        if (!raw.endsWith('Z') && !raw.contains('+')) {
          raw = '${raw.replaceAll(' ', 'T')}Z';
        }
        return DateTime.tryParse(raw)?.toLocal();
      }
      return null;
    }

    int? tipeProgressId;
    if (map['tipe_progress_id'] != null) {
      tipeProgressId = map['tipe_progress_id'] is int
          ? map['tipe_progress_id']
          : int.tryParse(map['tipe_progress_id'].toString());
    } else if (map['tipeProgress'] is Map) {
      tipeProgressId = TipeProgressId.fromKode(
        map['tipeProgress']['kode']?.toString(),
      );
    } else if (map['tipe_progress'] != null) {
      final legacy = map['tipe_progress'].toString().toLowerCase().trim();
      if (legacy == 'mulai') {
        tipeProgressId = TipeProgressId.mulai;
      } else if (legacy == 'selesai') {
        tipeProgressId = TipeProgressId.selesai;
      } else if (legacy == 'inpeksi' || legacy == 'inspeksi') {
        tipeProgressId = TipeProgressId.inspeksi;
      } else {
        tipeProgressId = TipeProgressId.progress;
      }
    }

    int? statusId;
    if (map['status_id'] != null) {
      statusId = map['status_id'] is int
          ? map['status_id']
          : int.tryParse(map['status_id'].toString());
    }

    if (statusId == null) {
      final dynamic rawLatest = map['latest_detail'] ?? map['latestDetail'];
      Map<String, dynamic>? latestDetailMap;
      if (rawLatest is Map) {
        latestDetailMap = Map<String, dynamic>.from(rawLatest);
      } else {
        final dynamic rawDetails = map['progress_details'] ?? map['detail_progress'] ?? map['progressDetails'];
        if (rawDetails is List && rawDetails.isNotEmpty) {
          final last = rawDetails.last;
          if (last is Map) {
            latestDetailMap = Map<String, dynamic>.from(last);
          }
        }
      }

      if (latestDetailMap != null) {
        final detailStatus = latestDetailMap['status']?.toString().toLowerCase();
        if (detailStatus == 'approved') {
          statusId = ProgressStatusId.verified; // 11
        } else if (detailStatus == 'rejected' || detailStatus == 'revisi') {
          statusId = ProgressStatusId.revisiRequested; // 14
        } else if (detailStatus == 'pending') {
          statusId = ProgressStatusId.submitted; // 10
        }
      }

      if (statusId == null) {
        if (tipeProgressId == TipeProgressId.selesai) {
          statusId = ProgressStatusId.submitted; // 10
        } else {
          statusId = ProgressStatusId.verified; // 11
        }
      }
    }

    int? submittedBy;
    if (map['submitted_by_user_id'] != null) {
      submittedBy = map['submitted_by_user_id'] is int
          ? map['submitted_by_user_id']
          : int.tryParse(map['submitted_by_user_id'].toString());
    } else if (map['submitted_by_pegawai_id'] != null) {
      submittedBy = map['submitted_by_pegawai_id'] is int
          ? map['submitted_by_pegawai_id']
          : int.tryParse(map['submitted_by_pegawai_id'].toString());
    }

    final dynamic rawDetails = map['progress_details'] ?? map['detail_progress'] ?? map['progressDetails'];
    List<ProgressDetailModel>? parsedDetails;
    if (rawDetails is List) {
      parsedDetails = rawDetails
          .whereType<Map>()
          .map((detail) => ProgressDetailModel.fromMap(Map<String, dynamic>.from(detail)))
          .toList();
    } else {
      final dynamic rawLatest = map['latest_detail'] ?? map['latestDetail'];
      if (rawLatest is Map) {
        parsedDetails = [ProgressDetailModel.fromMap(Map<String, dynamic>.from(rawLatest))];
      }
    }

    return WorkOrderProgressModel(
      id: map['id'],
      order: map['order'] ?? map['urutan'],
      workOrderId: map['workorder_id'],
      tipeProgressId: tipeProgressId,
      statusId: statusId,
      submittedByUserId: submittedBy,
      description: map['hasil_pengerjaan'],
      documentation: map['dokumentasi_progress'] != null
          ? List<DocumentationModel>.from(
              map['dokumentasi_progress'].map(
                (doc) => DocumentationModel.fromMap(doc),
              ),
            )
          : null,
      submitTime: parseUtcDateTime(map['waktu_submit']),
      createdAt: parseUtcDateTime(map['created_at']),
      updatedAt: parseUtcDateTime(map['updated_at']),
      progressDetails: parsedDetails,
      tahapan: map['tahapan'] != null
          ? (map['tahapan'] is int
                ? map['tahapan']
                : int.tryParse(map['tahapan'].toString()))
          : null,
      kategoriData: map['kategori_data'] != null
          ? Map<String, dynamic>.from(map['kategori_data'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    debugPrint("foto: $photos");
    return {
      'hasil_pengerjaan': description,
      'waktu_submit': submitTime?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      if (kategoriData != null) 'kategori_data': kategoriData,
      // submitted_by_user_id TIDAK dikirim — backend inject dari auth.
      'detail_progress':
          progressDetails?.map((detail) => detail.toMap()).toList() ?? [],
      'tahapan': tahapan,
    };
  }

  WorkOrderProgressEntity toEntity() {
    return WorkOrderProgressEntity(
      id: id,
      order: order,
      workOrderId: workOrderId,
      tipeProgressId: tipeProgressId,
      statusId: statusId,
      submittedByUserId: submittedByUserId,
      description: description,
      documentation: documentation,
      submitTime: submitTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
      progressDetail: progressDetails?.map((e) => e.toEntity()).toList(),
      tahapan: tahapan,
      kategoriData: kategoriData,
    );
  }

  factory WorkOrderProgressModel.fromEntity(WorkOrderProgressEntity entity) {
    return WorkOrderProgressModel(
      id: entity.id,
      order: entity.order,
      workOrderId: entity.workOrderId,
      tipeProgressId: entity.tipeProgressId,
      statusId: entity.statusId,
      submittedByUserId: entity.submittedByUserId,
      description: entity.description,
      documentation: entity.documentation,
      submitTime: entity.submitTime,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      progressDetails: entity.progressDetail
          ?.map((e) => ProgressDetailModel.fromEntity(e))
          .toList(),
      reviewAction: null,
      latitude: null,
      longitude: null,
      accuracy: null,
      tahapan: entity.tahapan,
      kategoriData: entity.kategoriData,
    );
  }

  @override
  WorkOrderProgressModel copyWith({
    int? id,
    int? order,
    int? workOrderId,
    int? tipeProgressId,
    int? statusId,
    int? submittedByUserId,
    String? description,
    List<dynamic>? documentation,
    DateTime? submitTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<dynamic>? progressDetail,
    List<XFile>? photos,
    String? reviewAction,
    double? latitude,
    double? longitude,
    double? accuracy,
    Map<String, dynamic>? kategoriData,
    int? tahapan,
  }) {
    return WorkOrderProgressModel(
      id: id ?? this.id,
      order: order ?? this.order,
      workOrderId: workOrderId ?? this.workOrderId,
      tipeProgressId: tipeProgressId ?? this.tipeProgressId,
      statusId: statusId ?? this.statusId,
      submittedByUserId: submittedByUserId ?? this.submittedByUserId,
      description: description ?? this.description,
      documentation: (documentation ?? this.documentation)
          ?.cast<DocumentationModel>(),
      submitTime: submitTime ?? this.submitTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progressDetails: (progressDetail ?? progressDetails)
          ?.cast<ProgressDetailModel>(),
      photos: photos ?? this.photos,
      reviewAction: reviewAction ?? this.reviewAction,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      kategoriData: kategoriData ?? this.kategoriData,
      tahapan: tahapan ?? this.tahapan,
    );
  }
}
