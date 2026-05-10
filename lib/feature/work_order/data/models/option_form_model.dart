import 'dart:convert';

import 'package:project_mobile_pdam/feature/work_order/domain/entities/option_form_entity.dart';

class OptionFormModel extends OptionFormEntity {
  const OptionFormModel({
    super.id,
    super.formId,
    super.optionName,
    super.parentId,
    super.order,
  });

  factory OptionFormModel.fromJson(String source) =>
      OptionFormModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory OptionFormModel.fromMap(Map<String, dynamic> map) {
    return OptionFormModel(
      id: map['id'],
      formId: map['detail_form_id'],
      optionName: map['nama_opsi'],
      parentId: map['parent'],
      order: map['order'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'detail_form_id': formId,
      'nama_opsi': optionName,
      'parent': parentId,
      'order': order,
    };
  }

  OptionFormEntity toEntity() {
    return OptionFormEntity(
      id: id,
      formId: formId,
      optionName: optionName,
      parentId: parentId,
      order: order,
    );
  }

  factory OptionFormModel.fromEntity(OptionFormEntity entity) {
    return OptionFormModel(
      id: entity.id,
      formId: entity.formId,
      optionName: entity.optionName,
      parentId: entity.parentId,
      order: entity.order,
    );
  }
}
