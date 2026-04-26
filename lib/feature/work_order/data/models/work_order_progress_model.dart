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
  });

  factory WorkOrderProgressModel.fromJson(String source) =>
      WorkOrderProgressModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory WorkOrderProgressModel.fromMap(Map<String, dynamic> map) {
    debugPrint("📢 Parsing Progress: $map");

    // TKT-05: backend sekarang mengirim `tipe_progress_id` (int) sebagai
    // sumber kebenaran. Kolom legacy `tipe_progress` (string) sudah tidak
    // ada lagi di response. Kalau suatu saat backend menambahkan eager
    // load relasi `tipeProgress`, prioritas pembacaan:
    //   1. tipe_progress_id (numeric) — primary
    //   2. tipeProgress.kode     — fallback via string
    //   3. tipe_progress         — fallback untuk data lama
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
      final legacy = map['tipe_progress'].toString();
      if (legacy == 'Mulai') {
        tipeProgressId = TipeProgressId.mulai;
      } else if (legacy == 'Selesai') {
        tipeProgressId = TipeProgressId.selesai;
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

    int? submittedBy;
    if (map['submitted_by_user_id'] != null) {
      submittedBy = map['submitted_by_user_id'] is int
          ? map['submitted_by_user_id']
          : int.tryParse(map['submitted_by_user_id'].toString());
    }

    return WorkOrderProgressModel(
      id: map['id'],
      order: map['order'],
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
      submitTime: map['waktu_submit'] != null
          ? DateTime.parse(map['waktu_submit'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      progressDetails: map['detail_progress'] != null
          ? List<ProgressDetailModel>.from(
              map['detail_progress'].map(
                (detail) => ProgressDetailModel.fromMap(detail),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    debugPrint("foto: $photos");
    return {
      'hasil_pengerjaan': description,
      'waktu_submit': submitTime?.toIso8601String(),
      // submitted_by_user_id TIDAK dikirim — backend inject dari auth.
      'detail_progress':
          progressDetails?.map((detail) => detail.toMap()).toList() ?? [],
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
    );
  }
}
