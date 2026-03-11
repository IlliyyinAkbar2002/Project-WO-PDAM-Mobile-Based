import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/documentation_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/progress_detail_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';

class WorkOrderProgressModel extends WorkOrderProgressEntity {
  final List<XFile>? photos;
  final List<ProgressDetailModel>? progressDetails;
  const WorkOrderProgressModel({
    super.id,
    super.order,
    super.workOrderId,
    super.progressType,
    super.description,
    super.documentation,
    super.submitTime,
    super.createdAt,
    super.updatedAt,
    this.progressDetails,
    // this.progressDetailModel,
    this.photos,
  });

  factory WorkOrderProgressModel.fromJson(String source) =>
      WorkOrderProgressModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory WorkOrderProgressModel.fromMap(Map<String, dynamic> map) {
    print("📢 Parsing Progress: $map");

    return WorkOrderProgressModel(
      id: map['id'],
      order: map['order'],
      workOrderId: map['workorder_id'],
      progressType: map['tipe_progress'],
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
      'detail_progress':
          progressDetails?.map((detail) => detail.toMap()).toList() ?? [],
    };
  }

  WorkOrderProgressEntity toEntity() {
    return WorkOrderProgressEntity(
      id: id,
      order: order,
      workOrderId: workOrderId,
      progressType: progressType,
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
      progressType: entity.progressType,
      description: entity.description,
      documentation: entity.documentation,
      submitTime: entity.submitTime,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      progressDetails: entity.progressDetail
          ?.map((e) => ProgressDetailModel.fromEntity(e))
          .toList(),
    );
  }
}
