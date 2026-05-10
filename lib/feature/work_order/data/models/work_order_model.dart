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
    super.lokasiText,
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
    super.progresPersen,
    super.kategoriForm,
  });

  factory WorkOrderModel.fromJson(String source) =>
      WorkOrderModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory WorkOrderModel.fromMap(Map<String, dynamic> map) {
    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    int? parseIdFromAny(dynamic value) {
      final direct = parseInt(value);
      if (direct != null) return direct;
      if (value is Map) {
        return parseInt(value['id']);
      }
      return null;
    }

    print("📢 Parsing Work Order: $map");
    print("📥 Data jenis_workorder yang diterima: ${map['jenis_workorder']}");
    print("📍 Data location yang diterima: ${map['location']}");

    // TKT-07: `petugas` (object) diganti `petugas_list` (array), lalu `assignment_members`.
    // Urutan fallback:
    //   1. assignment_members (kontrak baru, hasManyThrough)
    //   2. petugas_list (kontrak transisi, Many-to-Many)
    //   3. penerima_tugas (nama lama kalau ada)
    //   4. petugas (object tunggal, response legacy) → bungkus jadi list
    List<UserModel>? assignees;
    if (map['assignment_members'] is List) {
      assignees = (map['assignment_members'] as List)
          .whereType<Map>()
          .map((member) {
            final userMap = member['user'];
            if (userMap is Map) {
              return UserModel.fromMap(Map<String, dynamic>.from(userMap));
            }
            return null;
          })
          .whereType<UserModel>()
          .toList();
    } else if (map['petugas_list'] is List) {
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
    final UserModel? assignee = (assignees != null && assignees.isNotEmpty)
        ? assignees.first
        : null;

    final dynamic rawJenisWorkorder =
        map['jenis_workorder'] ?? map['workorder_type'];
    final dynamic rawJenisLokasi = map['jenis_lokasi'] ?? map['location_type'];
    final dynamic rawStatus = map['status'] ?? map['status_workorder'];

    return WorkOrderModel(
      id: map['id'],
      title: map['nama_workorder'] ?? map['judul_pekerjaan'],
      startDateTime: map['tanggal_mulai'] != null
          ? DateTime.tryParse(map['tanggal_mulai'])
          : map['waktu_penugasan'] != null
          ? DateTime.tryParse(map['waktu_penugasan'])
          : null,
      duration: parseInt(map['estimasi_durasi']),
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
      locationId: parseIdFromAny(map['location_id']),
      location: map['location'] != null
          ? MasterLocationModel.fromMap(map['location'])
          : null,
      lokasiText: map['lokasi'] as String?, // Parse field "lokasi" dari backend
      creator:
          parseIdFromAny(map['created_by_user_id']) ??
          parseIdFromAny(map['pic_id']),
      // `petugas_id` (FK tunggal) sudah dihapus di backend (TKT-07),
      // tapi id tunggal masih berguna utk backward-compat UI lain.
      assigneeId:
          parseIdFromAny(map['assigned_to']) ??
          parseIdFromAny(map['petugas_id']) ??
          assignee?.id,
      statusId: parseIdFromAny(map['status_id']),
      workOrderTypeId:
          parseIdFromAny(map['jenis_workorder_id']) ??
          parseIdFromAny(rawJenisWorkorder),
      splId: parseIdFromAny(map['lembur_spl_id']),
      locationTypeId:
          parseIdFromAny(map['jenis_lokasi_id']) ??
          parseIdFromAny(rawJenisLokasi),
      requiresApproval: parseIdFromAny(map['tipe_workorder_id']) == 2,
      assignees: assignees,
      assignee: assignee,
      locationType: rawJenisLokasi is Map
          ? LocationTypeModel.fromMap(Map<String, dynamic>.from(rawJenisLokasi))
          : null,
      workOrderType: rawJenisWorkorder is Map
          ? WorkOrderTypeModel.fromMap(
              Map<String, dynamic>.from(rawJenisWorkorder),
            )
          : null,
      status: rawStatus is Map
          ? StatusModel.fromMap(Map<String, dynamic>.from(rawStatus))
          : null,
      progresPersen: parseInt(map['progres_persen']),
      kategoriForm: rawJenisWorkorder is Map
          ? (rawJenisWorkorder['kategori_form'] as String?)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    // Kontrak terbaru backend memakai `assigned_to` (single user id).
    // `petugas_id` tetap dikirim sebagai fallback kompatibilitas.
    final List<int> ids = assigneeIds ?? const <int>[];
    final int? assignedTo =
        assigneeId ?? (ids.isNotEmpty ? ids.first : assignee?.id);
    return {
      'nama_workorder': title,
      'judul_pekerjaan': title, // fallback legacy
      'tanggal_mulai': startDateTime?.toIso8601String(),
      'waktu_penugasan': startDateTime?.toIso8601String(), // fallback legacy
      'estimasi_durasi': duration,
      'unit_waktu': durationUnit,
      'estimasi_selesai': endDateTime?.toIso8601String(),
      'lokasi':
          lokasiText ?? location?.nama, // Backend pakai field "lokasi" (string)
      // location_id, latitude, longitude sudah dipindah ke workorder_assignment
      // (tidak lagi dikirim saat create WO)
      // pic_id tidak dikirim - backend akan otomatis menggunakan authenticated user
      'status_id': statusId,
      'jenis_workorder_id': workOrderTypeId,
      'assigned_to': assignedTo,
      'petugas_id': ids,
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
      lokasiText: lokasiText,
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
      progresPersen: progresPersen,
      kategoriForm: kategoriForm,
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
      lokasiText: entity.lokasiText,
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
      progresPersen: entity.progresPersen,
      kategoriForm: entity.kategoriForm,
    );
  }
}
