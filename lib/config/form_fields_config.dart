import 'package:project_mobile_pdam/feature/work_order/domain/entities/location_type_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';

class FormFieldsConfig {
  static List<Map<String, dynamic>> getWorkOrderFields({
    required List<WorkOrderTypeEntity> jobTypeOptions,
    required List<LocationTypeEntity> locationTypeOptions,
    required List<UserEntity> assigneeOptions,
    required bool isDetailMode,
    required bool isOvertime,
  }) {
    return [
      {
        "type": "text",
        "key": "title",
        "label": "Judul Pekerjaan",
        "hint": "Masukkan judul",
      },
      {
        "type": "dropdown",
        "key": "jobType",
        "label": "Jenis Pekerjaan",
        "hint": "Pilih jenis pekerjaan",
        "options": jobTypeOptions
            .map((type) => {"value": type.id, "label": type.name})
            .toList(),
      },
      {
        "type": "dropdown",
        "key": "locationType",
        "label": "Jenis Lokasi",
        "hint": "Statis / Dinamis",
        "options": locationTypeOptions
            .map((type) => {"value": type.id, "label": type.locationType})
            .toList(),
      },
      {
        "key": "locationPicker",
        "type": "custom",
        "showIf": (formData) => formData["locationType"] == 1,
        "latitude": (formData) => formData["latitude"],
        "longitude": (formData) => formData["longitude"],
        "locationId": (formData) => formData["locationId"],
      },
      {
        "key": "timeEstimate",
        "type": "custom",
        "showIf": (formData) => true, // 🔹 Selalu tampil
        "isOvertime": isOvertime,
      },
      {
        "key": "isOvertime",
        "type":
            "hidden", // ✅ Bisa ditandai sebagai "hidden" karena tidak perlu ditampilkan di UI
        "value": isOvertime, // ✅ Simpan nilai isOvertime di form fields
      },
      {
        "type": "custom",
        "key": "assignees",
        "options": assigneeOptions, // 🔹 Menggunakan daftar user dari backend
      },
    ];
  }

  static List<Map<String, dynamic>> getDetailWorkOrderFields({
    required List<UserEntity> assigneeOptions,
    required bool isDetailMode,
    required bool isOvertime,
    required bool isAssignee,
    bool isAssignMode = false,
    int? status,
  }) {
    final bool readOnlyInDetail = isDetailMode && !isAssignMode;
    return [
      {
        "type": "text",
        "key": "title",
        "label": "Judul Pekerjaan",
        "hint": "Masukkan judul",
        "isReadOnly": readOnlyInDetail,
      },
      {
        "type": "text",
        "key": "jobType",
        "label": "Jenis Pekerjaan",
        "hint": "Pilih jenis pekerjaan",
        "isReadOnly": readOnlyInDetail,
      },
      {
        "type": "text",
        "key": "locationType",
        "label": "Jenis Lokasi",
        "hint": "Statis / Dinamis",
        "isReadOnly": readOnlyInDetail,
      },
      {
        "key": "locationPicker",
        "type": "custom",
        "showIf": (formData) => formData["locationType"] == "Statis",
        "latitude": (formData) => formData["latitude"],
        "longitude": (formData) => formData["longitude"],
        "locationId": (formData) => formData["locationId"],
        "isReadOnly": readOnlyInDetail,
      },
      {
        "key": "timeEstimate",
        "type": "custom",
        "showIf": (formData) => true, // 🔹 Selalu tampil
        "isOvertime": isOvertime,
        "startDateTime": (formData) => formData["startDateTime"],
        "duration": (formData) => formData["duration"],
        "durationUnit": (formData) => formData["durationUnit"],
        "endDateTime": (formData) => formData["endDateTime"],
        "isReadOnly": readOnlyInDetail,
        "status": status,
      },
      // {
      //   "type": "custom",
      //   "key": "estimateEditor",
      //   "showIf": isDetailMode,
      // },
      {
        "key": "isOvertime",
        "type":
            "hidden", // ✅ Bisa ditandai sebagai "hidden" karena tidak perlu ditampilkan di UI
        "value": isOvertime, // ✅ Simpan nilai isOvertime di form fields
      },
      {
        "type": "custom",
        "key": "assignee",
        "options": assigneeOptions,
        "isReadOnly": !isAssignMode,
        "showIf": !isAssignee,
      },
      {
        "type": "dropdown",
        "key": "picId",
        "label": "Koordinator (PIC)",
        "hint": "Pilih koordinator dari tim",
        "options": assigneeOptions
            .map(
              (e) => {
                "value": e.id,
                "label": e.employee?.name ?? e.email ?? 'Unknown',
              },
            )
            .toList(),
        "isReadOnly": !isAssignMode,
        "showIf": isAssignMode,
      },
      {
        "type": "text",
        "key": "nomorMeter",
        "label": "Nomor Meter",
        "hint": "Contoh: MTR-001",
        "isReadOnly": !isAssignMode,
        "showIf": isAssignMode,
      },
      {
        "type": "text",
        "key": "kondisiMeterAwal",
        "label": "Kondisi Meter Awal",
        "hint": "Contoh: Normal",
        "isReadOnly": !isAssignMode,
        "showIf": isAssignMode,
      },
    ];
  }
}
