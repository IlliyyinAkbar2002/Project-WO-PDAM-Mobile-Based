import 'dart:convert';

import 'package:project_mobile_pdam/feature/work_order/domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    super.id,
    super.name,
    super.nip,
    // super.birthDate,
    // super.gender,
    // super.address,
    // super.phone,
    // super.departmentId,
    // super.positionId,
  });

  factory EmployeeModel.fromJson(String source) =>
      EmployeeModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    print("🔧 EmployeeModel.fromMap received: $map");
    print("🔧 EmployeeModel.fromMap keys: ${map.keys.toList()}");

    // Handle multiple possible key names for name field
    final name =
        map['nama'] ?? map['name'] ?? map['full_name'] ?? map['nama_lengkap'];
    final nip = map['nip'] ?? map['employee_id'] ?? map['employee_number'];
    final id = map['id'] ?? map['pegawai_id'];

    print("🔧 Extracted values - id: $id, nama: $name, nip: $nip");

    if (name == null) {
      print(
        "⚠️ WARNING: Could not find name field in keys: ${map.keys.toList()}",
      );
    }
    if (nip == null) {
      print(
        "⚠️ WARNING: Could not find nip field in keys: ${map.keys.toList()}",
      );
    }

    return EmployeeModel(
      id: id,
      name: name,
      nip: nip,
      // birthDate: map['tanggal_lahir'] != null
      //     ? DateTime.tryParse(map['tanggal_lahir'])
      //     : null,
      // gender: map['jenis_kelamin'],
      // address: map['alamat'],
      // phone: map['telepon'],
      // departmentId: map['departemen_id'],
      // positionId: map['jabatan_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': name,
      'nip': nip,
      // 'tanggal_lahir': birthDate?.toIso8601String(),
      // 'jenis_kelamin': gender,
      // 'alamat': address,
      // 'telepon': phone,
      // 'departemen_id': departmentId,
      // 'jabatan_id': positionId,
    };
  }

  EmployeeEntity toEntity() {
    return EmployeeEntity(
      id: id,
      name: name,
      nip: nip,
      // birthDate: birthDate,
      // gender: gender,
      // address: address,
      // phone: phone,
      // departmentId: departmentId,
      // positionId: positionId,
    );
  }

  factory EmployeeModel.fromEntity(EmployeeEntity entity) {
    return EmployeeModel(
      id: entity.id,
      name: entity.name,
      nip: entity.nip,
      // birthDate: entity.birthDate,
      // gender: entity.gender,
      // address: entity.address,
      // phone: entity.phone,
      // departmentId: entity.departmentId,
      // positionId: entity.positionId,
    );
  }
}
