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
    super.updatedAt,
    super.tanggalTerbitLaporan,
    super.kategoriForm,
    super.detailKategori,
    super.prioritas,
    super.assignment,
    super.assignments,
    super.tahapanTertinggi,
    // super.departemenId,
    // super.departemenNama,
    super.isActive,
    super.assignedToPegawaiId,
    super.statusName,
    super.statusEnum,
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

    DateTime? parseDateTimeFromKeysIn(
      Map<String, dynamic>? source,
      List<String> keys,
    ) {
      if (source == null) return null;
      for (final key in keys) {
        final parsed = parseDateTime(source[key]);
        if (parsed != null) return parsed;
      }
      return null;
    }

    DateTime? parseDateTimeFromKeys(List<String> keys) =>
        parseDateTimeFromKeysIn(map, keys);

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

    UserModel? coordinator;
    List<UserModel>? assignees;
    final dynamic rawAssignmentMembers =
        assignmentMap?['members'] ??
        assignmentMap?['assignment_members'] ??
        map['assignment_members'];
    if (rawAssignmentMembers is List) {
      assignees = rawAssignmentMembers
          .whereType<Map>()
          .map((member) {
            // `index`/`show` mengirim anggota di key `user`; endpoint `history`
            // mengirimnya di key `pegawai`. Keduanya = objek Pegawai (id = pegawai_id).
            final userMap = member['user'] ?? member['pegawai'];
            UserModel? parsedUser;
            if (userMap is Map) {
              parsedUser = UserModel.fromMap(
                Map<String, dynamic>.from(userMap),
              );
            }
            if (parsedUser != null) {
              final String? peranDirect =
                  member['peran']?.toString() ?? member['role']?.toString();
              final Map? pivotMap = member['pivot'] is Map
                  ? member['pivot'] as Map
                  : null;
              final String? peranPivot =
                  pivotMap?['peran']?.toString() ??
                  pivotMap?['role']?.toString();
              final String? peran = peranDirect ?? peranPivot;
              if (peran == 'koordinator') {
                coordinator = parsedUser;
              }
            }
            return parsedUser;
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

    // final Map<String, dynamic>? departemenMap = parseMap(map['departemen']);
    // final int? departemenId =
    //     parseIdFromAny(map['departemen_id']) ?? parseIdFromAny(departemenMap);
    // final String? departemenNama = departemenMap?['nama'] as String?;
    final int? assignedToPegawaiId =
        parseIdFromAny(map['assigned_to']) ??
        parseIdFromAny(map['assigned_to_id']);

    final dynamic rawIsActive = map['is_active'];
    final bool? isActive = rawIsActive == null
        ? null
        : (rawIsActive is bool
              ? rawIsActive
              : (rawIsActive.toString().toLowerCase() == 'true' ||
                    rawIsActive.toString() == '1'));

    final dynamic rawStatusEnum = map['status'] ?? map['status_workorder'];
    final String? statusEnum = rawStatusEnum is String
        ? rawStatusEnum.trim()
        : (rawStatusEnum is Map
              ? (rawStatusEnum['status']?.toString().trim() ??
                    rawStatusEnum['name']?.toString().trim())
              : null);

    final dynamic rawStatusValue = map['status'] ?? map['status_workorder'];
    final String? statusName = rawStatusValue is String
        ? (rawStatusValue.trim().isEmpty ? null : rawStatusValue.trim())
        : (rawStatusValue is Map ? rawStatusValue['status'] as String? : null);

    int? resolvedStatusId =
        parseIdFromAny(map['status_id']) ??
        (map['status'] is Map ? parseIdFromAny(map['status']['id']) : null) ??
        (map['status_workorder'] is Map
            ? parseIdFromAny(map['status_workorder']['id'])
            : null);
    if (resolvedStatusId == null && statusEnum != null) {
      switch (statusEnum.trim()) {
        case 'Pending':
          resolvedStatusId = 12;
          break;
        case 'Proses':
          resolvedStatusId = 13;
          break;
        case 'Selesai':
          resolvedStatusId = 6;
          break;
        case 'Tutup':
          resolvedStatusId = 17;
          break;
      }
    }

    const startDateKeys = [
      'tanggal_mulai',
      'tanggalMulai',
      'waktu_penugasan',
      'waktuPenugasan',
    ];
    const endDateKeys = [
      'estimasi_selesai',
      'estimasiSelesai',
      'tanggal_selesai',
      'tanggalSelesai',
    ];

    final DateTime? assignmentStartDateTime = parseDateTimeFromKeysIn(
      assignmentMap,
      startDateKeys,
    );
    final DateTime? assignmentEndDateTime = parseDateTimeFromKeysIn(
      assignmentMap,
      endDateKeys,
    );
    final int? assignmentDuration =
        parseInt(assignmentMap?['estimasi_durasi']) ??
        parseInt(assignmentMap?['duration']) ??
        parseInt(assignmentMap?['durasi']);
    final String? assignmentRawDurationUnit =
        assignmentMap?['unit_waktu']?.toString() ??
        assignmentMap?['duration_unit']?.toString() ??
        assignmentMap?['durasi_unit']?.toString();
    final String? assignmentNormalizedDurationUnit = normalizeDurationUnit(
      assignmentRawDurationUnit,
    );
    final String? assignmentLokasiText = assignmentMap?['lokasi'] as String?;

    final DateTime? parsedStartDateTime =
        assignmentStartDateTime ?? parseDateTimeFromKeys(startDateKeys);
    final DateTime? parsedEndDateTime =
        assignmentEndDateTime ?? parseDateTimeFromKeys(endDateKeys);
    final String? rawDurationUnit =
        assignmentRawDurationUnit ??
        map['unit_waktu']?.toString() ??
        map['duration_unit']?.toString() ??
        map['durasi_unit']?.toString();
    final String? normalizedDurationUnit = normalizeDurationUnit(
      rawDurationUnit,
    );
    String? resolvedDurationUnit = normalizedDurationUnit ?? rawDurationUnit;
    int? resolvedDuration =
        assignmentDuration ??
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

    final UserModel? assignee =
        coordinator ??
        ((assignees != null && assignees.isNotEmpty)
            ? (parsedAssigneeId != null
                  ? assignees.firstWhere(
                      (user) => user.id == parsedAssigneeId,
                      orElse: () => assignees!.first,
                    )
                  : assignees.first)
            : assigneeCandidate);

    final Map<String, dynamic>? assignmentLocationMap =
        parseMap(assignmentMap?['location']) ?? parseMap(map['location']);

    // Tanggal terbit laporan: hanya tersedia dari endpoint `/v1/workorder/history`
    // yang meng-eager-load relasi `laporan_workorder` (hasOne). BE mengirim UTC 'Z'
    // → normalisasi ke lokal (WIB) via parseUtcDateTime, konsisten dgn model detail.
    final Map<String, dynamic>? laporanMap = parseMap(map['laporan_workorder']);
    final DateTime? tanggalTerbitLaporan = parseUtcDateTime(
      laporanMap?['tanggal_terbit'],
    );

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
      lokasiText: assignmentLokasiText,
      startDateTime: assignmentStartDateTime,
      duration: assignmentDuration,
      durationUnit:
          assignmentNormalizedDurationUnit ?? assignmentRawDurationUnit,
      endDateTime: assignmentEndDateTime,
    );

    return WorkOrderModel(
      id: map['id'],
      title: map['nama_workorder'] ?? map['judul_pekerjaan'],
      startDateTime: parsedStartDateTime,
      duration: resolvedDuration,
      durationUnit: resolvedDurationUnit,
      endDateTime: parsedEndDateTime,
      lokasiText:
          assignmentLokasiText ??
          map['lokasi'] as String?, // Parse field "lokasi" dari backend
      creator:
          parseIdFromAny(map['created_by_user_id']) ??
          parseIdFromAny(map['pic_id']),
      statusId: resolvedStatusId,
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
      prioritas: (map['prioritas'] as String?)?.trim().isNotEmpty == true
          ? (map['prioritas'] as String).trim().toLowerCase()
          : null,
      createdAt: parseUtcDateTime(map['created_at']),
      updatedAt: parseUtcDateTime(map['updated_at']),
      tanggalTerbitLaporan: tanggalTerbitLaporan,
      assignment: assignment,
      tahapanTertinggi: parseInt(map['tahapan_tertinggi']),
      // departemenId: departemenId,
      // departemenNama: departemenNama,
      isActive: isActive,
      assignedToPegawaiId: assignedToPegawaiId,
      statusName: statusName,
      statusEnum: statusEnum,
    );
  }

  Map<String, dynamic> toMap() {
    final List<int> ids = assignment?.assigneeIds ?? const <int>[];
    final int? assignedTo =
        assignment?.assigneeId ??
        (ids.isNotEmpty ? ids.first : assignment?.assignee?.id);

    String? formatDateTime(DateTime? dt) {
      if (dt == null) return null;
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final ss = dt.second.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm:$ss';
    }

    final payload = <String, dynamic>{
      'nama_workorder': title,
      // legacy fallback (akan diabaikan oleh validator BE baru):
      'judul_pekerjaan': title,
      'tanggal_mulai': formatDateTime(startDateTime),
      'jenis_workorder_id': workOrderTypeId,
      'lokasi': (lokasiText != null && lokasiText!.trim().isNotEmpty)
          ? lokasiText
          : assignment?.location?.nama,
      'deskripsi': assignment?.description,
      'assigned_to': assignedTo,
      'prioritas': prioritas ?? 'sedang',
    };

    payload.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    return payload;
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
      updatedAt: updatedAt,
      tanggalTerbitLaporan: tanggalTerbitLaporan,
      kategoriForm: kategoriForm,
      detailKategori: detailKategori,
      prioritas: prioritas,
      assignment: assignment,
      assignments: assignments,
      tahapanTertinggi: tahapanTertinggi,
      // departemenId: departemenId,
      // departemenNama: departemenNama,
      isActive: isActive,
      assignedToPegawaiId: assignedToPegawaiId,
      statusName: statusName,
      statusEnum: statusEnum,
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
      updatedAt: entity.updatedAt,
      tanggalTerbitLaporan: entity.tanggalTerbitLaporan,
      kategoriForm: entity.kategoriForm,
      detailKategori: entity.detailKategori,
      prioritas: entity.prioritas,
      assignment: entity.assignment,
      assignments: entity.assignments,
      tahapanTertinggi: entity.tahapanTertinggi,
      // departemenId: entity.departemenId,
      // departemenNama: entity.departemenNama,
      isActive: entity.isActive,
      assignedToPegawaiId: entity.assignedToPegawaiId,
      statusName: entity.statusName,
      statusEnum: entity.statusEnum,
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
    if (map['jaringan'] != null) return 'jaringan';
    if (map['infrastruktur'] != null) return 'infrastruktur';
    if (map['meter'] != null) return 'meter';

    if (map['kategori'] is String) {
      final k = map['kategori'] as String;
      if (k == 'jaringan' || k == 'infrastruktur' || k == 'meter') return k;
    }
    if (rawJenisWorkorder is Map && rawJenisWorkorder['kategori'] is String) {
      final k = rawJenisWorkorder['kategori'] as String;
      if (k == 'jaringan' || k == 'infrastruktur' || k == 'meter') return k;
    }

    if (map['kategori_form'] is String) {
      return map['kategori_form'] as String;
    }
    if (rawJenisWorkorder is Map &&
        rawJenisWorkorder['kategori_form'] is String) {
      return rawJenisWorkorder['kategori_form'] as String;
    }

    final namaWo = (map['nama_workorder'] ?? map['judul_pekerjaan'] ?? '')
        .toString()
        .toLowerCase();
    final deskripsi = (map['deskripsi'] ?? '').toString().toLowerCase();
    final combinedText = '$namaWo $deskripsi';

    if (_isJaringanName(combinedText)) return 'jaringan';
    if (_isInfrastrukturName(combinedText)) return 'infrastruktur';

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
