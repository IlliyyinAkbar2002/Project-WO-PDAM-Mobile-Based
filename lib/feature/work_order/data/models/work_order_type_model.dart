import 'dart:convert';

import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';

class WorkOrderTypeModel extends WorkOrderTypeEntity {
  const WorkOrderTypeModel({super.id, required super.name, super.kategoriForm});

  factory WorkOrderTypeModel.fromJson(String source) =>
      WorkOrderTypeModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory WorkOrderTypeModel.fromMap(Map<String, dynamic> map) {
    print("📢 parsing jenis workorder: $map");
    return WorkOrderTypeModel(
      id: map['id'],
      name: map['nama'] ?? 'Unknown',
      kategoriForm: map['kategori_form'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': name,
      if (kategoriForm != null) 'kategori_form': kategoriForm,
    };
  }

  WorkOrderTypeEntity toEntity() {
    return WorkOrderTypeEntity(id: id, name: name, kategoriForm: kategoriForm);
  }

  factory WorkOrderTypeModel.fromEntity(WorkOrderTypeEntity entity) {
    return WorkOrderTypeModel(
      id: entity.id,
      name: entity.name,
      kategoriForm: entity.kategoriForm,
    );
  }
}
