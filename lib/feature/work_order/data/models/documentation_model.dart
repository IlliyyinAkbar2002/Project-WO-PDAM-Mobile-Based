import 'dart:convert';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/documentation_entity.dart';

class DocumentationModel extends DocumentationEntity {
  const DocumentationModel({super.id, super.workOrderProgressId, super.url});

  factory DocumentationModel.fromJson(String source) =>
      DocumentationModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory DocumentationModel.fromMap(Map<String, dynamic> map) {
    return DocumentationModel(
      id: map['id'],
      workOrderProgressId: map['progress_workorder_id'],
      url: map['url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'url': url};
  }

  DocumentationEntity toEntity() {
    return DocumentationEntity(
      id: id,
      workOrderProgressId: workOrderProgressId,
      url: url,
    );
  }

  factory DocumentationModel.fromEntity(DocumentationEntity entity) {
    return DocumentationModel(
      id: entity.id,
      workOrderProgressId: entity.workOrderProgressId,
      url: entity.url,
    );
  }
}
