import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';

class DynamicFormConfig {
  static List<Map<String, dynamic>> getDynamicFormFields({
    required List<ProgressDetailEntity> details,
    // required bool isDetailMode,
    // required List<WorkOrderTypeEntity> jobTypeOptions,
    // required List<LocationTypeEntity> locationTypeOptions,
    // required List<UserEntity> assigneeOptions,
    // required bool isOvertime,
  }) {
    return details
        .map(
          (detail) => {
            "type": detail.form?.fieldType,
            "key": detail.form?.id.toString(),
            "label": detail.form?.fieldName,
            "hint": detail.form?.hintText,
            "parent": detail.form?.parentId,
            "options": detail.form?.optionsForm
                ?.map(
                  (option) => {
                    "value": option.id,
                    "label": option.optionName,
                    "optionParent": option.parentId,
                  },
                )
                .toList(),
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> getDetailDynamicFormFields({
    required List<ProgressDetailEntity> details,
    required bool isDetailMode,
  }) {
    return details
        .map(
          (detail) => {
            "type": detail.form?.fieldType == "dropdown"
                ? "text"
                : detail.form?.fieldType,
            "key": detail.id.toString(),
            "label": detail.form?.fieldName,
            "hint": detail.form?.hintText,
            "isReadOnly": isDetailMode,
          },
        )
        .toList();
  }
}
