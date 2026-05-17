import 'dart:convert';
import 'package:project_mobile_pdam/feature/work_order/data/models/location_type_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/master_location_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/status_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/user_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_type_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/assignment_workorder_entity.dart';

import '/feature/work_order/domain/entities/work_order_entity.dart';

class WorkOrderModel extends WorkOrderEntity {
  const WorkOrderModel({
    super.id,
    required super.title,
    super.startDateTime,
    super.duration,
    super.durationUnit,
    super.endDateTime,
    super.lokasiText,
    super.creator,
    super.statusId,
    super.workOrderTypeId,
    super.splId,
    super.locationTypeId,
    super.requiresApproval,
    super.locationType,
    super.workOrderType,
    super.status,
    super.progresPersen,
    super.createdAt,
    super.kategoriForm,
    super.detailKategori,
    super.assignment,
    super.assignments,
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

    double? parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    Map<String, dynamic>? parseMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    DateTime? parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return null;
        return DateTime.tryParse(trimmed);
      }
      return null;
    }

    DateTime? parseDateTimeFromKeys(List<String> keys) {
      for (final key in keys) {
        final parsed = parseDateTime(map[key]);
        if (parsed != null) return parsed;
      }
      return null;
    }

    String? normalizeDurationUnit(dynamic value) {
      final normalized = (value ?? '').toString().trim().toLowerCase();
      if (normalized.isEmpty) return null;
      if (normalized == 'jam' ||
          normalized == 'j' ||
          normalized == 'h' ||
          normalized == 'hour' ||
          normalized == 'hours') {
        return 'Jam';
      }
      if (normalized == 'hari' ||
          normalized == 'd' ||
          normalized == 'day' ||
          normalized == 'days') {
        return 'Hari';
      }
      if (normalized == 'bulan' ||
          normalized == 'b' ||
          normalized == 'bln' ||
          normalized == 'month' ||
          normalized == 'months') {
        return 'Bulan';
      }
      return null;
    }

    int? inferDuration(DateTime? start, DateTime? end, String? unit) {
      if (start == null || end == null) return null;
      final diff = end.difference(start);
      if (diff.isNegative) return null;

      switch (unit) {
        case 'Hari':
          if (diff.inHours % 24 == 0) {
            return diff.inHours ~/ 24;
          }
          break;
        case 'Bulan':
          final months =
              (end.year - start.year) * 12 + (end.month - start.month);
          if (months > 0) return months;
          break;
        case 'Jam':
          return diff.inHours;
      }

      if (diff.inHours >= 24 && diff.inHours % 24 == 0) {
        return diff.inHours ~/ 24;
      }
      if (diff.inHours > 0) return diff.inHours;
      if (diff.inMinutes > 0) return 1;
      return 0;
    }

    int? parseIdFromAny(dynamic value) {
      final direct = parseInt(value);
      if (direct != null) return direct;
      if (value is Map) {
        return parseInt(value['id']);
      }
      return null;
    }

    UserModel? parseUser(dynamic value) {
      final userMap = parseMap(value);
      if (userMap == null) return null;
      return UserModel.fromMap(userMap);
    }

    final Map<String, dynamic>? assignmentMap =
        parseMap(map['workorder_assignment']) ??
        parseMap(map['work_order_assignment']) ??
        parseMap(map['workorderAssignment']) ??
        parseMap(map['assignment']);

    List<UserModel>? assignees;
    final dynamic rawAssignmentMembers =
        assignmentMap?['members'] ??
        assignmentMap?['assignment_members'] ??
        map['assignment_members'];
    if (rawAssignmentMembers is List) {
      assignees = rawAssignmentMembers
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
    final UserModel? assigneeCandidate =
        (assignees != null && assignees.isNotEmpty)
        ? assignees.first
        : parseUser(assignmentMap?['spv']) ?? parseUser(map['spv']);

    final dynamic rawJenisWorkorder =
        map['jenis_workorder'] ?? map['workorder_type'];
    final dynamic rawJenisLokasi = map['jenis_lokasi'] ?? map['location_type'];
    final dynamic rawStatus = map['status'] ?? map['status_workorder'];

    final resolvedKategori = _resolveKategoriForm(map, rawJenisWorkorder);
    final detailKategori = _extractDetailKategoriMap(map);
    final DateTime? parsedStartDateTime = parseDateTimeFromKeys([
      'tanggal_mulai',
      'tanggalMulai',
      'waktu_penugasan',
      'waktuPenugasan',
    ]);
    final DateTime? parsedEndDateTime = parseDateTimeFromKeys([
      'estimasi_selesai',
      'estimasiSelesai',
      'tanggal_selesai',
      'tanggalSelesai',
    ]);
    final String? rawDurationUnit =
        map['unit_waktu']?.toString() ??
        map['duration_unit']?.toString() ??
        map['durasi_unit']?.toString();
    final String? normalizedDurationUnit = normalizeDurationUnit(
      rawDurationUnit,
    );
    String? resolvedDurationUnit = normalizedDurationUnit ?? rawDurationUnit;
    int? resolvedDuration =
        parseInt(map['estimasi_durasi']) ??
        parseInt(map['duration']) ??
        parseInt(map['durasi']);

    if (resolvedDuration == null &&
        parsedStartDateTime != null &&
        parsedEndDateTime != null) {
      final inferredDuration = inferDuration(
        parsedStartDateTime,
        parsedEndDateTime,
        normalizeDurationUnit(resolvedDurationUnit),
      );
      if (inferredDuration != null) {
        resolvedDuration = inferredDuration;
        if (normalizeDurationUnit(resolvedDurationUnit) == null) {
          resolvedDurationUnit =
              inferredDuration > 0 &&
                  parsedEndDateTime.difference(parsedStartDateTime).inHours %
                          24 ==
                      0
              ? 'Hari'
              : 'Jam';
        }
      }
    }

    final parsedAssigneeId =
        parseIdFromAny(assignmentMap?['assigned_to']) ??
        parseIdFromAny(assignmentMap?['petugas_id']) ??
        parseIdFromAny(assignmentMap?['spv_id']) ??
        parseIdFromAny(assignmentMap?['spv']) ??
        parseIdFromAny(map['assigned_to']) ??
        parseIdFromAny(map['petugas_id']) ??
        assigneeCandidate?.id;

    final UserModel? assignee = (assignees != null && assignees.isNotEmpty)
        ? (parsedAssigneeId != null
              ? assignees.firstWhere(
                  (user) => user.id == parsedAssigneeId,
                  orElse: () => assignees!.first,
                )
              : assignees.first)
        : assigneeCandidate;

    final Map<String, dynamic>? assignmentLocationMap =
        parseMap(assignmentMap?['location']) ?? parseMap(map['location']);

    final assignment = AssignmentWorkorderEntity(
      id: parseIdFromAny(assignmentMap?['id']),
      workOrderId:
          parseIdFromAny(assignmentMap?['workorder_id']) ??
          parseIdFromAny(assignmentMap?['work_order_id']) ??
          parseIdFromAny(map['id']),
      assignees: assignees,
      assignee: assignee,
      assigneeId: parsedAssigneeId,
      latitude:
          parseDouble(assignmentMap?['latitude']) ??
          parseDouble(map['latitude']),
      longitude:
          parseDouble(assignmentMap?['longitude']) ??
          parseDouble(map['longitude']),
      accuracy:
          parseDouble(assignmentMap?['accuracy']) ??
          parseDouble(map['accuracy']),
      locationId:
          parseIdFromAny(assignmentMap?['location_id']) ??
          parseIdFromAny(map['location_id']) ??
          parseIdFromAny(assignmentMap?['location']),
      location: assignmentLocationMap != null
          ? MasterLocationModel.fromMap(assignmentLocationMap)
          : null,
      description:
          assignmentMap?['deskripsi'] as String? ??
          assignmentMap?['description'] as String? ??
          map['deskripsi'] as String?,
    );

    return WorkOrderModel(
      id: map['id'],
      title: map['nama_workorder'] ?? map['judul_pekerjaan'],
      startDateTime: parsedStartDateTime,
      duration: resolvedDuration,
      durationUnit: resolvedDurationUnit,
      endDateTime: parsedEndDateTime,
      lokasiText: map['lokasi'] as String?, // Parse field "lokasi" dari backend
      creator:
          parseIdFromAny(map['created_by_user_id']) ??
          parseIdFromAny(map['pic_id']),
      statusId: parseIdFromAny(map['status_id']),
      workOrderTypeId:
          parseIdFromAny(map['jenis_workorder_id']) ??
          parseIdFromAny(rawJenisWorkorder),
      splId: parseIdFromAny(map['lembur_spl_id']),
      locationTypeId:
          parseIdFromAny(map['jenis_lokasi_id']) ??
          parseIdFromAny(rawJenisLokasi),
      requiresApproval: parseIdFromAny(map['tipe_workorder_id']) == 2,
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
      detailKategori: detailKategori,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
      assignment: assignment,
    );
  }

  Map<String, dynamic> toMap() {
    final List<int> ids = assignment?.assigneeIds ?? const <int>[];
    final int? assignedTo =
        assignment?.assigneeId ??
        (ids.isNotEmpty ? ids.first : assignment?.assignee?.id);
    return {
      'nama_workorder': title,
      'judul_pekerjaan': title, // fallback legacy
      'tanggal_mulai': startDateTime?.toIso8601String(),
      'waktu_penugasan': startDateTime?.toIso8601String(), // fallback legacy
      'estimasi_durasi': duration,
      'unit_waktu': durationUnit,
      'estimasi_selesai': endDateTime?.toIso8601String(),
      'lokasi':
          lokasiText ??
          assignment?.location?.nama, // Backend pakai field "lokasi" (string)
      'deskripsi': assignment?.description,
      'status_id': statusId,
      'jenis_workorder_id': workOrderTypeId,
      'assigned_to': assignedTo,
      'petugas_id': ids,
      'latitude': assignment?.latitude,
      'longitude': assignment?.longitude,
      'location_id': assignment?.locationId,
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
      lokasiText: lokasiText,
      creator: creator,
      statusId: statusId,
      workOrderTypeId: workOrderTypeId,
      splId: splId,
      locationTypeId: locationTypeId,
      requiresApproval: requiresApproval,
      locationType: locationType,
      workOrderType: workOrderType,
      status: status,
      progresPersen: progresPersen,
      createdAt: createdAt,
      kategoriForm: kategoriForm,
      detailKategori: detailKategori,
      assignment: assignment,
      assignments: assignments,
    );
  }

  factory WorkOrderModel.fromEntity(WorkOrderEntity entity) {
    return WorkOrderModel(
      id: entity.id,
      title: entity.title,
      startDateTime: entity.startDateTime,
      duration: entity.duration,
      durationUnit: entity.durationUnit,
      endDateTime: entity.endDateTime,
      lokasiText: entity.lokasiText,
      creator: entity.creator,
      statusId: entity.statusId,
      workOrderTypeId: entity.workOrderTypeId,
      splId: entity.splId,
      locationTypeId: entity.locationTypeId,
      requiresApproval: entity.requiresApproval,
      progresPersen: entity.progresPersen,
      createdAt: entity.createdAt,
      kategoriForm: entity.kategoriForm,
      detailKategori: entity.detailKategori,
      assignment: entity.assignment,
      assignments: entity.assignments,
    );
  }

  static Map<String, dynamic>? _extractDetailKategoriMap(
    Map<String, dynamic> map,
  ) {
    final dynamic raw =
        map['wo_jaringan'] ??
        map['wo_infrastruktur'] ??
        map['wo_meter'] ??
        map['form_kategori'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return null;
  }

  static String? _resolveKategoriForm(
    Map<String, dynamic> map,
    dynamic rawJenisWorkorder,
  ) {
    if (map['wo_jaringan'] != null) return 'jaringan';
    if (map['wo_infrastruktur'] != null) return 'infrastruktur';
    if (map['wo_meter'] != null) return 'meter';

    final namaWo = (map['nama_workorder'] ?? map['judul_pekerjaan'] ?? '')
        .toString()
        .toLowerCase();
    final deskripsi = (map['deskripsi'] ?? '').toString().toLowerCase();
    final combinedText = '$namaWo $deskripsi';

    if (_isJaringanName(combinedText)) return 'jaringan';
    if (_isInfrastrukturName(combinedText)) return 'infrastruktur';

    if (map['kategori_form'] is String) {
      return map['kategori_form'] as String;
    }
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
