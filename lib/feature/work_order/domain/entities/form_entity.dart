import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/option_form_entity.dart';

class FormEntity extends Equatable {
  final int? id;
  final int? workOrderTypeId;
  final String? fieldName;
  final String? fieldType;
  final String? hintText;
  final String? type;
  final String? unit;
  final int? min;
  final int? max;
  final int? parentId;
  final int? order;
  final bool? isRequired;
  final String? description;
  final List<OptionFormEntity>? optionsForm;
  final bool? isHidden;
  final bool? isVisible;

  const FormEntity({
    this.id,
    this.workOrderTypeId,
    this.fieldName,
    this.fieldType,
    this.hintText,
    this.type,
    this.unit,
    this.min,
    this.max,
    this.parentId,
    this.order,
    this.isRequired,
    this.description,
    this.optionsForm,
    this.isHidden,
    this.isVisible,
  });

  @override
  List<Object?> get props => [
    id,
    workOrderTypeId,
    fieldName,
    fieldType,
    hintText,
    type,
    unit,
    min,
    max,
    parentId,
    order,
    isRequired,
    description,
    optionsForm,
    isHidden,
    isVisible,
  ];

  FormEntity copyWith({
    int? id,
    int? workOrderTypeId,
    String? fieldName,
    String? fieldType,
    String? hintText,
    String? type,
    String? unit,
    int? min,
    int? max,
    int? parentId,
    int? order,
    bool? isRequired,
    String? description,
    List<OptionFormEntity>? optionsForm,
    bool? isHidden,
    bool? isVisible,
  }) {
    return FormEntity(
      id: id ?? this.id,
      workOrderTypeId: workOrderTypeId ?? this.workOrderTypeId,
      fieldName: fieldName ?? this.fieldName,
      fieldType: fieldType ?? this.fieldType,
      hintText: hintText ?? this.hintText,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      min: min ?? this.min,
      max: max ?? this.max,
      parentId: parentId ?? this.parentId,
      order: order ?? this.order,
      isRequired: isRequired ?? this.isRequired,
      description: description ?? this.description,
      optionsForm: optionsForm ?? this.optionsForm,
      isHidden: isHidden ?? this.isHidden,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
