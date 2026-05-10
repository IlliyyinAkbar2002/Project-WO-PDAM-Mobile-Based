import 'dart:convert';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/assignees_entity.dart';

class AssigneesModel extends AssigneesEntity {
  const AssigneesModel({super.workOrderId, super.userId});

  factory AssigneesModel.fromJson(String source) =>
      AssigneesModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory AssigneesModel.fromMap(Map<String, dynamic> map) {
    return AssigneesModel(
      workOrderId: map['workorder_id'],
      userId: map['user_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'workorder_id': workOrderId, 'user_id': userId};
  }

  AssigneesEntity toEntity() {
    return AssigneesEntity(workOrderId: workOrderId, userId: userId);
  }

  factory AssigneesModel.fromEntity(AssigneesEntity entity) {
    return AssigneesModel(
      workOrderId: entity.workOrderId,
      userId: entity.userId,
    );
  }
}
