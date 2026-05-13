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
    super.createdAt,
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
    print(
      "🏷️ kategori_form root: ${map['kategori_form']}, nama_workorder: ${map['nama_workorder']}, deskripsi: ${map['deskripsi']}",
    );
    print(
      "🏷️ wo_jaringan: ${map['wo_jaringan']}, wo_infrastruktur: ${map['wo_infrastruktur']}, wo_meter: ${map['wo_meter']}",
    );

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

    final resolvedKategori = _resolveKategoriForm(map, rawJenisWorkorder);
    print(
      "🏷️ RESOLVED kategoriForm: $resolvedKategori for WO: ${map['nama_workorder']}",
    );

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
      kategoriForm: resolvedKategori,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
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
      createdAt: createdAt,
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
      createdAt: entity.createdAt,
      kategoriForm: entity.kategoriForm,
    );
  }

  static String? _resolveKategoriForm(
    Map<String, dynamic> map,
    dynamic rawJenisWorkorder,
  ) {
    // 1. Deteksi dari keberadaan payload kategori di response (paling akurat)
    if (map['wo_jaringan'] != null) return 'jaringan';
    if (map['wo_infrastruktur'] != null) return 'infrastruktur';
    if (map['wo_meter'] != null) return 'meter';

    // 2. Inferensi dari nama_workorder + deskripsi
    //    Ini lebih reliable daripada kategori_form dari jenis_workorder
    //    ketika WO belum punya record di tabel wo_* (belum di-assign SPV)
    final namaWo = (map['nama_workorder'] ?? map['judul_pekerjaan'] ?? '')
        .toString()
        .toLowerCase();
    final deskripsi = (map['deskripsi'] ?? '').toString().toLowerCase();
    final combinedText = '$namaWo $deskripsi';

    if (_isJaringanName(combinedText)) return 'jaringan';
    if (_isInfrastrukturName(combinedText)) return 'infrastruktur';

    // 3. Langsung dari root level (backend appended attribute)
    if (map['kategori_form'] is String) {
      return map['kategori_form'] as String;
    }

    // 4. Dari nested jenis_workorder object
    if (rawJenisWorkorder is Map &&
        rawJenisWorkorder['kategori_form'] is String) {
      return rawJenisWorkorder['kategori_form'] as String;
    }

    // 5. Fallback: coba tebak dari nama jenis workorder
    if (rawJenisWorkorder is Map) {
      final nama = (rawJenisWorkorder['nama'] as String?)?.toLowerCase() ?? '';
      if (_isJaringanName(nama)) return 'jaringan';
      if (_isInfrastrukturName(nama)) return 'infrastruktur';
      if (_isMeterName(nama)) return 'meter';
    }

    // 6. Meter check dari nama WO (hanya kalau eksplisit)
    if (combinedText.contains('meter') || combinedText.contains('kalibrasi')) {
      return 'meter';
    }

    return null;
  }

  static bool _isJaringanName(String nama) {
    return nama.contains('pipa') ||
        nama.contains('jaringan') ||
        nama.contains('saluran') ||
        nama.contains('kebocoran');
  }

  static bool _isInfrastrukturName(String nama) {
    return nama.contains('pompa') ||
        nama.contains('reservoir') ||
        nama.contains('infrastruktur') ||
        nama.contains('aset') ||
        nama.contains('inspeksi') ||
        nama.contains('pemeliharaan');
  }

  static bool _isMeterName(String nama) {
    return nama.contains('meter') || nama.contains('kalibrasi');
  }
}
