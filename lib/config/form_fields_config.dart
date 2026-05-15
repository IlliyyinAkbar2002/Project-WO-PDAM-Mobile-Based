import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';

class FormFieldsConfig {
  static List<Map<String, dynamic>> getWorkOrderFields({
    required List<WorkOrderTypeEntity> jobTypeOptions,
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
        "type": "text",
        "key": "lokasi",
        "label": "Lokasi",
        "hint": "Masukkan nama lokasi",
      },
      {
        "key": "locationPicker",
        "type": "custom",
        "showIf": (formData) => true,
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
    String? kategoriForm,
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
        "key": "lokasi",
        "label": "Lokasi",
        "hint": "Nama lokasi",
        "isReadOnly": readOnlyInDetail,
      },
      {
        "key": "locationPicker",
        "type": "custom",
        // BUG 4: Sembunyikan map untuk SPV saat assign mode. Cukup staff yang perlu validasi map.
        "showIf": !isAssignMode,
        "latitude": (formData) => formData["latitude"],
        "longitude": (formData) => formData["longitude"],
        "locationId": (formData) => formData["locationId"],
        "isReadOnly": readOnlyInDetail,
      },
      {
        "key": "timeEstimate",
        "type": "custom",
        "showIf": (formData) => true,
        "isOvertime": isOvertime,
        // BUG 2: Saat isAssignMode, field Mulai harus kosong (SPV yang menentukan).
        "startDateTime": (formData) =>
            isAssignMode ? null : formData["startDateTime"],
        "duration": (formData) => formData["duration"],
        "durationUnit": (formData) => formData["durationUnit"],
        "endDateTime": (formData) =>
            isAssignMode ? null : formData["endDateTime"],
        "isReadOnly": readOnlyInDetail,
        "status": status,
        "hideStartDateTime": false,
      },
      {"key": "isOvertime", "type": "hidden", "value": isOvertime},
      {
        "type": "custom",
        "key": "assignee",
        "options": assigneeOptions,
        // BUG 3: Read-only saat bukan assign mode (view-only untuk SPV yang sudah assign).
        // isReadOnly=false hanya saat isAssignMode=true.
        "isReadOnly": !isAssignMode,
        // BUG 3: Tampil untuk SPV (isAssignee=false), tidak tampil untuk staff (isAssignee=true).
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
      // ─── Deskripsi Pekerjaan ────────────────────────────────────────
      {
        "type": "textarea",
        "key": "deskripsiPekerjaan",
        "label": "Deskripsi Pekerjaan",
        "hint": "Masukkan deskripsi atau catatan pekerjaan",
        "isReadOnly": !isAssignMode,
        "showIf": isDetailMode || isAssignMode,
      },
      // ─── Form Kategori: Meter ───────────────────────────────────────
      if (kategoriForm == 'meter' ||
          (kategoriForm == null && isAssignMode)) ...[
        {
          "type": "text",
          "key": "nomorMeter",
          "label": "Nomor Meter",
          "hint": "Contoh: MTR-001",
          "isReadOnly": !isAssignMode,
          "showIf": true,
        },
        {
          "type": "text",
          "key": "kondisiMeterAwal",
          "label": "Kondisi Meter Awal",
          "hint": "Contoh: Normal",
          "isReadOnly": !isAssignMode,
          "showIf": true,
        },
      ],
      // ─── Form Kategori: Jaringan ────────────────────────────────────
      if (kategoriForm == 'jaringan') ...[
        {
          "type": "dropdown",
          "key": "jenisPipa",
          "label": "Jenis Pipa",
          "hint": "Pilih jenis pipa",
          "options": [
            {"value": "PVC", "label": "PVC"},
            {"value": "HDPE", "label": "HDPE"},
            {"value": "Galvanis", "label": "Galvanis"},
            {"value": "Besi Cor", "label": "Besi Cor"},
          ],
          "isReadOnly": !isAssignMode,
          "isDisabled": !isAssignMode,
          "showIf": true,
        },
        {
          "type": "text",
          "key": "diameterPipa",
          "label": "Diameter Pipa (inch)",
          "hint": "Contoh: 4",
          "isReadOnly": !isAssignMode,
          "showIf": true,
        },
        {
          "type": "text",
          "key": "panjangPipa",
          "label": "Panjang Pipa (meter)",
          "hint": "Contoh: 50",
          "isReadOnly": !isAssignMode,
          "showIf": true,
        },
        {
          "type": "dropdown",
          "key": "tingkatKerusakan",
          "label": "Tingkat Kerusakan",
          "hint": "Pilih tingkat kerusakan",
          "options": [
            {"value": "Ringan", "label": "Ringan"},
            {"value": "Sedang", "label": "Sedang"},
            {"value": "Berat", "label": "Berat"},
          ],
          "isReadOnly": !isAssignMode,
          "isDisabled": !isAssignMode,
          "showIf": true,
        },
      ],
      // ─── Form Kategori: Infrastruktur ───────────────────────────────
      if (kategoriForm == 'infrastruktur') ...[
        {
          "type": "text",
          "key": "namaAset",
          "label": "Nama Aset",
          "hint": "Contoh: Pompa Booster RT 05",
          "isReadOnly": !isAssignMode,
          "showIf": true,
        },
        {
          "type": "dropdown",
          "key": "jenisAset",
          "label": "Jenis Aset",
          "hint": "Pilih jenis aset",
          "options": [
            {"value": "Pompa", "label": "Pompa"},
            {"value": "Reservoir", "label": "Reservoir"},
            {"value": "IPA", "label": "IPA"},
            {"value": "Genset", "label": "Genset"},
            {"value": "Panel", "label": "Panel"},
          ],
          "isReadOnly": !isAssignMode,
          "isDisabled": !isAssignMode,
          "showIf": true,
        },
        {
          "type": "text",
          "key": "kapasitas",
          "label": "Kapasitas",
          "hint": "Contoh: 500 L/menit",
          "isReadOnly": !isAssignMode,
          "showIf": true,
        },
        {
          "type": "text",
          "key": "kondisiAwal",
          "label": "Kondisi Awal",
          "hint": "Deskripsi kondisi sebelum pemeliharaan",
          "isReadOnly": !isAssignMode,
          "showIf": true,
        },
      ],
    ];
  }
}
