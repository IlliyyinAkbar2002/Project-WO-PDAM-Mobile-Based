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
  });

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory UserModel.fromMap(Map<String, dynamic> map) {
    debugPrint("📢 parsing user: $map");
    return UserModel(
      id: map['id'],
      employeeId: map['pegawai_id'],
      roleId: map['role_id'],
      email: map['email'],
      employee: map['pegawai'] != null
          ? EmployeeModel.fromMap(map['pegawai'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'email': email,
      'role_id': roleId,
      'pegawai': employee,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      employeeId: employeeId,
      email: email,
      roleId: roleId,
      employee: employee,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      employeeId: entity.employeeId,
      email: entity.email,
      roleId: entity.roleId,
      employee: entity.employee,
    );
  }
}
