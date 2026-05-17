import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    super.id,
    super.name,
    super.nip,
    super.jabatanId,
    super.jabatan,
    super.departemenId,
    super.departemen,
  });

  factory EmployeeModel.fromJson(String source) =>
      EmployeeModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    debugPrint("🔧 EmployeeModel.fromMap received: $map");
    debugPrint("🔧 EmployeeModel.fromMap keys: ${map.keys.toList()}");

    // Handle multiple possible key names for name field
    final name =
        map['nama'] ?? map['name'] ?? map['full_name'] ?? map['nama_lengkap'];
    final nip = map['nip'] ?? map['employee_id'] ?? map['employee_number'];
    final id = map['id'] ?? map['pegawai_id'];

    // Kontrak baru `/v1/pegawai/filter` memuat `jabatan_id`, `jabatan`,
    // `departemen_id`, dan `departemen` langsung di dalam `pegawai`.
    // Nama alternatif (`position_id`/`position`) di-handle untuk kompatibel
    // dengan transformasi `fetchMe()` yang masih memakai gaya lama.
    final jabatanId = map['jabatan_id'] ?? map['position_id'];
    final jabatan = map['jabatan'] ?? map['position'];
    final departemenId = map['departemen_id'] ?? map['department_id'];
    final departemen = map['departemen'] ?? map['department'];

    debugPrint(
      "🔧 Extracted values - id: $id, nama: $name, nip: $nip, "
      "jabatan_id: $jabatanId, jabatan: $jabatan, "
      "departemen_id: $departemenId, departemen: $departemen",
    );

    if (name == null) {
      debugPrint(
        "⚠️ WARNING: Could not find name field in keys: ${map.keys.toList()}",
      );
    }
    if (nip == null) {
      debugPrint(
        "⚠️ WARNING: Could not find nip field in keys: ${map.keys.toList()}",
      );
    }

    return EmployeeModel(
      id: id,
      name: name,
      nip: nip,
      jabatanId: jabatanId,
      jabatan: jabatan,
      departemenId: departemenId,
      departemen: departemen,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': name,
      'nip': nip,
      'jabatan_id': jabatanId,
      'jabatan': jabatan,
      'departemen_id': departemenId,
      'departemen': departemen,
    };
  }

  EmployeeEntity toEntity() {
    return EmployeeEntity(
      id: id,
      name: name,
      nip: nip,
      jabatanId: jabatanId,
      jabatan: jabatan,
      departemenId: departemenId,
      departemen: departemen,
    );
  }

  factory EmployeeModel.fromEntity(EmployeeEntity entity) {
    return EmployeeModel(
      id: entity.id,
      name: entity.name,
      nip: entity.nip,
      jabatanId: entity.jabatanId,
      jabatan: entity.jabatan,
      departemenId: entity.departemenId,
      departemen: entity.departemen,
    );
  }
}
