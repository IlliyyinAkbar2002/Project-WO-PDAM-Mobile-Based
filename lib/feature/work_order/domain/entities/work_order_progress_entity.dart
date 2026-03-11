import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/documentation_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';

class WorkOrderProgressEntity extends Equatable {
  final int? id;
  final int? order;
  final int? workOrderId;
  final String? progressType;
  final String? description;
  final List<DocumentationEntity>? documentation;
  final DateTime? submitTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ProgressDetailEntity>? progressDetail;

  const WorkOrderProgressEntity({
    this.id,
    this.order,
    this.workOrderId,
    this.progressType,
    this.description,
    this.documentation,
    this.submitTime,
    this.createdAt,
    this.updatedAt,
    this.progressDetail,
  });

  @override
  List<Object?> get props => [
    id,
    order,
    workOrderId,
    progressType,
    description,
    documentation,
    submitTime,
    createdAt,
    updatedAt,
    progressDetail,
  ];

  WorkOrderProgressEntity copyWith({
    int? id,
    int? order,
    int? workOrderId,
    String? progressType,
    String? description,
    List<DocumentationEntity>? documentation,
    DateTime? submitTime,
    int? statusId,
    int? progressWorkOrderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProgressDetailEntity>? progressDetail,
  }) {
    return WorkOrderProgressEntity(
      id: id ?? this.id,
      order: order ?? this.order,
      workOrderId: workOrderId ?? this.workOrderId,
      progressType: progressType ?? this.progressType,
      description: description ?? this.description,
      documentation: documentation ?? this.documentation,
      submitTime: submitTime ?? this.submitTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progressDetail: progressDetail ?? this.progressDetail,
    );
  }
}
