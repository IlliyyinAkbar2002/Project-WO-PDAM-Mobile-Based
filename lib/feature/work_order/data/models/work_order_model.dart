import 'dart:convert';
import 'package:project_mobile_pdam/feature/work_order/data/models/location_type_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/master_location_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/status_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/user_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_type_model.dart';

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
    super.locationId,
    super.location,
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
  });

  factory WorkOrderModel.fromJson(String source) =>
      WorkOrderModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory WorkOrderModel.fromMap(Map<String, dynamic> map) {
    print("📢 Parsing Work Order: $map");
    print("📥 Data jenis_workorder yang diterima: ${map['jenis_workorder']}");
    print("📍 Data location yang diterima: ${map['location']}");

    // TKT-07: `petugas` (object) diganti `petugas_list` (array).
    // Urutan fallback:
    //   1. petugas_list (kontrak baru, Many-to-Many)
    //   2. penerima_tugas (nama lama kalau ada)
    //   3. petugas (object tunggal, response legacy) → bungkus jadi list
    List<UserModel>? assignees;
    if (map['petugas_list'] is List) {
      assignees = (map['petugas_list'] as List)
          .whereType<Map>()
          .map((user) => UserModel.fromMap(Map<String, dynamic>.from(user)))
          .toList();
    } else if (map['penerima_tugas'] is List) {
      assignees = (map['penerima_tugas'] as List)
          .whereType<Map>()
          .map((user) => UserModel.fromMap(Map<String, dynamic>.from(user)))
          .toList();
    } else if (map['petugas'] is Map) {
      assignees = [
        UserModel.fromMap(Map<String, dynamic>.from(map['petugas'])),
      ];
    }

    // Untuk backward-compat kode UI yang masih baca `assignee` single,
    // isi otomatis dari elemen pertama `assignees`.
    final UserModel? assignee =
        (assignees != null && assignees.isNotEmpty) ? assignees.first : null;

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
      locationId: map['location_id'],
      location: map['location'] != null
          ? MasterLocationModel.fromMap(map['location'])
          : null,
      creator: map['pic_id'],
      // `petugas_id` (FK tunggal) sudah dihapus di backend (TKT-07),
      // tapi id tunggal masih berguna utk backward-compat UI lain.
      assigneeId: map['petugas_id'] ?? assignee?.id,
      statusId: map['status_id'],
      workOrderTypeId: map['jenis_workorder_id'],
      splId: map['lembur_spl_id'],
      locationTypeId: map['jenis_lokasi_id'],
      requiresApproval:
          (map['tipe_workorder_id'] != null && map['tipe_workorder_id'] == 2),
      assignees: assignees,
      assignee: assignee,
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
      'location_id': locationId, // ID dari MasterLocation untuk radius check
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
      locationId: locationId,
      location: location,
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
      locationId: entity.locationId,
      location: entity.location,
      creator: entity.creator,
      assigneeId: entity.assigneeId,
      statusId: entity.statusId,
      workOrderTypeId: entity.workOrderTypeId,
      splId: entity.splId,
      locationTypeId: entity.locationTypeId,
      requiresApproval: entity.requiresApproval,
      assigneeIds: entity.assigneeIds,
      assignee: entity.assignee,
      assignees: entity.assignees,
    );
  }
}
