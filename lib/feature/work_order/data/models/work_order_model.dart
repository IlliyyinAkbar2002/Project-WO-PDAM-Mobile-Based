import 'dart:convert';
import 'package:mobile_intern_pdam/feature/work_order/data/models/location_type_model.dart';
import 'package:mobile_intern_pdam/feature/work_order/data/models/status_model.dart';
import 'package:mobile_intern_pdam/feature/work_order/data/models/user_model.dart';
import 'package:mobile_intern_pdam/feature/work_order/data/models/work_order_type_model.dart';

import '/feature/work_order/domain/entities/work_order_entity.dart';

class WorkOrderModel extends WorkOrderEntity {
  const WorkOrderModel({
    super.id,
    required super.title,
    super.startDateTime,
    super.duration,
    super.durationUnit,
    super.endDateTime,
    super.longitude,
    super.latitude,
    super.creator,
    super.assigneeId,
    super.statusId,
    super.workOrderTypeId,
    super.splId,
    super.locationTypeId,
    super.requiresApproval,
    super.assigneeIds,
    super.assignee,
    super.assignees,
    super.locationType,
    super.workOrderType,
    super.status,
    // this.locationType,
    // this.assignees,
  });

  factory WorkOrderModel.fromJson(String source) =>
      WorkOrderModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory WorkOrderModel.fromMap(Map<String, dynamic> map) {
    print("📢 Parsing Work Order: $map");
    print("📥 Data jenis_workorder yang diterima: ${map['jenis_workorder']}");

    return WorkOrderModel(
      id: map['id'],
      title: map['judul_pekerjaan'],
      startDateTime: map['waktu_penugasan'] != null
          ? DateTime.tryParse(map['waktu_penugasan'])
          : null,
      duration: map['estimasi_durasi'],
      durationUnit: map['unit_waktu'],
      endDateTime: map['estimasi_selesai'] != null
          ? DateTime.tryParse(map['estimasi_selesai'])
          : null,
      longitude: map['longitude'] != null
          ? double.tryParse(map['longitude'].toString())
          : null,
      latitude: map['latitude'] != null
          ? double.tryParse(map['latitude'].toString())
          : null,
      creator: map['pic_id'],
      assigneeId: map['petugas_id'],
      statusId: map['status_id'],
      workOrderTypeId: map['jenis_workorder_id'],
      splId: map['lembur_spl_id'],
      locationTypeId: map['jenis_lokasi_id'],
      requiresApproval:
          (map['tipe_workorder_id'] != null && map['tipe_workorder_id'] == 2),
      assignees: map['penerima_tugas'] != null
          ? List<UserModel>.from(
              map['penerima_tugas'].map((user) => UserModel.fromMap(user)),
            )
          : null,
      assignee: map['petugas'] != null
          ? UserModel.fromMap(map['petugas'])
          : null,
      locationType: map['jenis_lokasi'] != null
          ? LocationTypeModel.fromMap(map['jenis_lokasi'])
          : null,
      workOrderType: map['jenis_workorder'] != null
          ? WorkOrderTypeModel.fromMap(map['jenis_workorder'])
          : null,
      status: map['status'] != null ? StatusModel.fromMap(map['status']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'judul_pekerjaan': title,
      'waktu_penugasan': startDateTime?.toIso8601String(),
      'estimasi_durasi': duration,
      'unit_waktu': durationUnit,
      'estimasi_selesai': endDateTime?.toIso8601String(),
      'longitude': longitude,
      'latitude': latitude,
      // pic_id tidak dikirim - backend akan otomatis menggunakan authenticated user
      'status_id': statusId,
      'jenis_workorder_id': workOrderTypeId,
      'jenis_lokasi_id': locationTypeId,
      'tipe_workorder_id': requiresApproval ? 2 : 1,
      'petugas_id': assigneeIds,
    };
  }

  WorkOrderEntity toEntity() {
    return WorkOrderEntity(
      id: id,
      title: title,
      startDateTime: startDateTime,
      duration: duration,
      durationUnit: durationUnit,
      endDateTime: endDateTime,
      longitude: longitude,
      latitude: latitude,
      creator: creator,
      assigneeId: assigneeId,
      statusId: statusId,
      workOrderTypeId: workOrderTypeId,
      splId: splId,
      locationTypeId: locationTypeId,
      requiresApproval: requiresApproval,
      assignee: assignee,
      assignees: assignees,
      locationType: locationType,
      workOrderType: workOrderType,
      status: status,
    );
  }

  factory WorkOrderModel.fromEntity(WorkOrderEntity entity) {
    return WorkOrderModel(
      title: entity.title,
      startDateTime: entity.startDateTime,
      duration: entity.duration,
      durationUnit: entity.durationUnit,
      endDateTime: entity.endDateTime,
      longitude: entity.longitude,
      latitude: entity.latitude,
      creator: entity.creator,
      assigneeId: entity.assigneeId,
      statusId: entity.statusId,
      workOrderTypeId: entity.workOrderTypeId,
      splId: entity.splId,
      locationTypeId: entity.locationTypeId,
      requiresApproval: entity.requiresApproval,
      assigneeIds: entity.assigneeIds,
      assignee: entity.assignee,
    );
  }
}
