import 'dart:convert';

import 'package:project_mobile_pdam/feature/work_order/domain/entities/role_entity.dart';

class RoleModel extends RoleEntity {
  const RoleModel({super.id, super.name, super.description});

  factory RoleModel.fromJson(String source) =>
      RoleModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description};
  }

  RoleEntity toEntity() {
    return RoleEntity(id: id, name: name, description: description);
  }

  factory RoleModel.fromEntity(RoleEntity entity) {
    return RoleModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
    );
  }
}
