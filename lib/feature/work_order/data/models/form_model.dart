import 'dart:convert';

import 'package:project_mobile_pdam/feature/work_order/data/models/option_form_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/form_entity.dart';

class FormModel extends FormEntity {
  const FormModel({
    super.id,
    super.workOrderTypeId,
    super.fieldName,
    super.fieldType,
    super.hintText,
    super.type,
    super.unit,
    super.min,
    super.max,
    super.parentId,
    super.order,
    super.isRequired,
    super.description,
    super.optionsForm,
    super.isHidden,
    super.isVisible,
  });

  factory FormModel.fromJson(String source) =>
      FormModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory FormModel.fromMap(Map<String, dynamic> map) {
    return FormModel(
      id: map['id'],
      workOrderTypeId: map['jenis_workorder_id'],
      fieldName: map['nama_field'],
      fieldType: map['tipe_field'],
      hintText: map['hint_text'],
      type: map['tipe_data'],
      unit: map['unit_satuan'],
      min: map['min'],
      max: map['max'],
      parentId: map['parent'],
      order: map['order'],
      isRequired: map['sifat'] == 'mandatory' ? true : false,
      description: map['description'],
      optionsForm: map['option_form'] != null
          ? List<OptionFormModel>.from(
              map['option_form'].map(
                (detail) => OptionFormModel.fromMap(detail),
              ),
            )
          : null,
      isHidden: map['is_hidden'] == 1,
      isVisible: map['is_visible'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jenis_workorder_id': workOrderTypeId,
      'nama_field': fieldName,
      'tipe_field': fieldType,
      'tipe_data': type,
      'unit_satuan': unit,
      'min': min,
      'max': max,
      'parent': parentId,
      'order': order,
      'is_required': isRequired == true ? 1 : 0,
      'description': description,
      // 'option_form': optionsForm?.map((x) => x.toMap()).toList(),
      'is_hidden': isHidden == true ? 1 : 0,
      'is_visible': isVisible == true ? 1 : 0,
    };
  }

  FormEntity toEntity() {
    return FormEntity(
      id: id,
      workOrderTypeId: workOrderTypeId,
      fieldName: fieldName,
      fieldType: fieldType,
      hintText: hintText,
      type: type,
      unit: unit,
      min: min,
      max: max,
      parentId: parentId,
      order: order,
      isRequired: isRequired,
      description: description,
      optionsForm: optionsForm,
      isHidden: isHidden,
      isVisible: isVisible,
    );
  }

  factory FormModel.fromEntity(FormEntity entity) {
    return FormModel(
      id: entity.id,
      workOrderTypeId: entity.workOrderTypeId,
      fieldName: entity.fieldName,
      fieldType: entity.fieldType,
      type: entity.type,
      unit: entity.unit,
      min: entity.min,
      max: entity.max,
      parentId: entity.parentId,
      order: entity.order,
      isRequired: entity.isRequired,
      description: entity.description,
      isHidden: entity.isHidden,
      isVisible: entity.isVisible,
    );
  }
}
