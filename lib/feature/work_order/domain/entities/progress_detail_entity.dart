import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/form_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';

class ProgressDetailEntity extends Equatable {
  final int? id;
  final int? workOrderProgressId;
  final int? detailFormId;
  final String? value;
  final WorkOrderProgressEntity? workOrderProgress;
  final FormEntity? form;

  const ProgressDetailEntity({
    this.id,
    this.workOrderProgressId,
    this.detailFormId,
    this.value,
    this.workOrderProgress,
    this.form,
  });

  @override
  List<Object?> get props => [
    id,
    workOrderProgressId,
    detailFormId,
    value,
    workOrderProgress,
    form,
  ];

  ProgressDetailEntity copyWith({
    int? id,
    int? workOrderProgressId,
    int? detailFormId,
    String? value,
    WorkOrderProgressEntity? workOrderProgress,
    FormEntity? form,
  }) {
    return ProgressDetailEntity(
      id: id ?? this.id,
      workOrderProgressId: workOrderProgressId ?? this.workOrderProgressId,
      detailFormId: detailFormId ?? this.detailFormId,
      value: value ?? this.value,
      workOrderProgress: workOrderProgress ?? this.workOrderProgress,
      form: form ?? this.form,
    );
  }
}
