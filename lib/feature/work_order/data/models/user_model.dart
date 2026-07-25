import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/employee_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    super.id,
    super.employeeId,
    super.roleId,
    super.email,
    super.employee,
    super.isBusy,
    super.busyWorkorderId,
    super.busyWorkorderName,
  });

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory UserModel.fromMap(Map<String, dynamic> map) {
    debugPrint("📢 parsing user: $map");
    final hasFlatEmployee = map['pegawai'] == null && (map['nama'] != null || map['name'] != null);
    return UserModel(
      id: map['id'],
      employeeId: map['pegawai_id'] ?? (hasFlatEmployee ? map['id'] : null),
      roleId: map['role_id'],
      email: map['email'],
      employee: map['pegawai'] != null
          ? EmployeeModel.fromMap(map['pegawai'])
          : (hasFlatEmployee ? EmployeeModel.fromMap(map) : null),
      isBusy: _parseBool(map['is_busy']),
      busyWorkorderId: _parseInt(map['busy_workorder_id']),
      busyWorkorderName: map['busy_workorder_name']?.toString(),
    );
  }

  /// Field beban kerja belum tentu dikirim backend (mis. endpoint lama atau
  /// backend belum ter-deploy) → dianggap tidak sibuk. Angka/string juga
  /// diterima karena MySQL bisa mengirim `1`/`0` untuk kolom boolean.
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'email': email,
      'role_id': roleId,
      'pegawai': employee,
      'is_busy': isBusy,
      'busy_workorder_id': busyWorkorderId,
      'busy_workorder_name': busyWorkorderName,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      employeeId: employeeId,
      email: email,
      roleId: roleId,
      employee: employee,
      isBusy: isBusy,
      busyWorkorderId: busyWorkorderId,
      busyWorkorderName: busyWorkorderName,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      employeeId: entity.employeeId,
      email: entity.email,
      roleId: entity.roleId,
      employee: entity.employee,
      isBusy: entity.isBusy,
      busyWorkorderId: entity.busyWorkorderId,
      busyWorkorderName: entity.busyWorkorderName,
    );
  }
}
