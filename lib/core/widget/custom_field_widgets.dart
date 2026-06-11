import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/input_chip/editable_chip_field.dart';
import 'package:project_mobile_pdam/core/widget/location_picker.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/time_estimate.dart';
import 'package:project_mobile_pdam/core/widget/kuota_upload_stepper.dart';

typedef CustomFieldBuilder =
    Widget Function(
      Map<String, dynamic> field,
      Map<String, dynamic> formData,
      Function(String, dynamic) onFieldChanged,
    );

class CustomFieldWidgets {
  static dynamic _resolveFieldValue(
    Map<String, dynamic> field,
    Map<String, dynamic> formData,
    String key,
  ) {
    final dynamic value = field[key];
    if (value is Function) {
      return value(formData);
    }
    if (field.containsKey(key)) {
      return value;
    }
    return formData[key];
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static Map<String, CustomFieldBuilder> get fields => {
    "locationPicker": (field, formData, onFieldChanged) => LocationPicker(
      isStatic: true,
      isReadOnly: field["isReadOnly"] ?? false,
      latitude: _parseDouble(formData["latitude"]),
      longitude: _parseDouble(formData["longitude"]),
      locationId: formData["locationId"],
      locationName: formData["locationName"],
      onLocationSelected:
          (
            lat,
            long, {
            int? locationId,
            int? radiusMeter,
            String? locationName,
          }) {
            if (!(field["isReadOnly"] ?? false)) {
              onFieldChanged("latitude", lat);
              onFieldChanged("longitude", long);
              onFieldChanged("locationId", locationId);
              onFieldChanged("radiusMeter", radiusMeter);
              onFieldChanged("locationName", locationName);
              // Update field "lokasi" text jika user pilih dari search
              if (locationName != null && locationName.isNotEmpty) {
                onFieldChanged("lokasi", locationName);
              }
            }
          },
    ),
    "timeEstimate": (field, formData, onFieldChanged) => TimeEstimate(
      isOvertime: field["isOvertime"] ?? false, // ✅ Ambil dari formData
      isReadOnly: field["isReadOnly"] ?? false,
      hideStartDateTime: field["hideStartDateTime"] ?? false,
      status: field["status"],
      startDateTime: _resolveFieldValue(
        field,
        formData,
        "startDateTime",
      ), // ✅ Data awal
      duration: _resolveFieldValue(field, formData, "duration"), // ✅ Data awal
      durationUnit: _resolveFieldValue(
        field,
        formData,
        "durationUnit",
      ), // ✅ Data awal
      endDateTime: _resolveFieldValue(
        field,
        formData,
        "endDateTime",
      ), // ✅ Data awal
      onChanged: (startDateTime, duration, durationUnit, endDateTime) {
        if (!(field["isReadOnly"] ?? false)) {
          onFieldChanged("startDateTime", startDateTime);
          onFieldChanged("duration", duration);
          onFieldChanged("durationUnit", durationUnit);
          onFieldChanged("endDateTime", endDateTime);
        }
      },
    ),
    "kuotaUploadProgress": (field, formData, onFieldChanged) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: KuotaUploadStepper(
        value: formData["kuotaUploadProgress"] ?? 2,
        onChanged: (val) {
          if (!(field["isReadOnly"] ?? false)) {
            onFieldChanged("kuotaUploadProgress", val);
          }
        },
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFAFBACA)),
        ),
        padding: const EdgeInsets.all(16),
        titleStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2D499B),
          letterSpacing: -0.3,
          height: 1.6,
        ),
      ),
    ),
    // "estimateEditor": (field, formData, onFieldChanged) => EstimateEditor(),
    "assignees": (field, formData, onFieldChanged) => EditableChipField(
      isReadOnly: field["isReadOnly"] ?? false,
      userList: field["options"] ?? [],
      initialSelectedUsers: formData["assignees"] ?? [], // ✅ Data awal
      onChanged: (selectedUsers) {
        onFieldChanged("assignees", selectedUsers); // ✅ Update formData
      },
      key: ValueKey(formData["assignees"]), // 🔹 Supaya UI ter-refresh
    ),

    "assignee": (field, formData, onFieldChanged) => EditableChipField(
      isReadOnly: field["isReadOnly"] ?? false,
      userList: field["options"] ?? [],
      initialSelectedUsers: formData["assignee"] ?? [], // ✅ Data awal
      onChanged: (selectedUsers) {
        onFieldChanged("assignee", selectedUsers); // ✅ Update formData
      },
      key: ValueKey(formData["assignee"]), // 🔹 Supaya UI ter-refresh
    ),
  };
}
