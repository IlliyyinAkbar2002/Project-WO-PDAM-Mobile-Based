import 'dart:convert';

import 'package:project_mobile_pdam/feature/work_order/domain/entities/status_entity.dart';

class StatusModel extends StatusEntity {
  const StatusModel({super.id, super.status});

  factory StatusModel.fromJson(String source) =>
      StatusModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(id: map['id'], status: map['nama']);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nama': status};
  }

  StatusEntity toEntity() {
    return StatusEntity(id: id, status: status);
  }

  factory StatusModel.fromEntity(StatusEntity entity) {
    return StatusModel(id: entity.id, status: entity.status);
  }
}
