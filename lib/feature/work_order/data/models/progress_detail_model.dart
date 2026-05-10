import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/form_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';

class ProgressDetailModel extends ProgressDetailEntity {
  final XFile? image;
  const ProgressDetailModel({
    super.id,
    super.workOrderProgressId,
    super.detailFormId,
    super.value,
    super.workOrderProgress,
    super.form,
    this.image,
  });

  factory ProgressDetailModel.fromJson(String source) =>
      ProgressDetailModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory ProgressDetailModel.fromMap(Map<String, dynamic> map) {
    return ProgressDetailModel(
      id: map['id'],
      workOrderProgressId: map['progress_workorder_id'],
      detailFormId: map['detail_form_id'],
      value: map['value'],
      workOrderProgress: map['progress_workorder'] != null
          ? WorkOrderProgressModel.fromMap(map['progress_workorder'])
          : null,
      form: map['detail_form'] != null
          ? FormModel.fromMap(map['detail_form'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {'detail_form_id': detailFormId, 'value': value};
  }

  ProgressDetailEntity toEntity() {
    return ProgressDetailEntity(
      id: id,
      workOrderProgressId: workOrderProgressId,
      detailFormId: detailFormId,
      value: value,
      workOrderProgress: workOrderProgress,
      form: form,
    );
  }

  factory ProgressDetailModel.fromEntity(ProgressDetailEntity entity) {
    return ProgressDetailModel(
      id: entity.id,
      workOrderProgressId: entity.workOrderProgressId,
      detailFormId: entity.detailFormId,
      value: entity.value,
    );
  }
}
