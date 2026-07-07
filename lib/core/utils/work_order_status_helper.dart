import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/config/theme/app_color.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_entity.dart';

class WorkOrderStatusHelper {
  // Label per status (key selalu lowercase).
  static const Map<String, String> _labels = {
    'pending': 'Pending',
    'proses': 'proses',
    'in progress': 'proses',
    'selesai': 'Selesai',
    'tutup': 'Ditutup',
    'ditolak': 'Ditolak',
  };

  // Warna per status (key selalu lowercase).
  static const Map<String, Color> _colors = {
    'pending': Color(0xFF94A3B8), // Netral / Abu
    'proses': Color(0xFF0EA5E9), // Biru
    'in progress': Color(0xFF0EA5E9), // Biru
    'selesai': Color(0xFF10B981), // Hijau
    'tutup': Color(0xFFEF4444), // Merah
    'ditolak': Color(0xFFEF4444), // Merah
  };

  // Ambil status mentah dari sumber mana pun yang tersedia.
  static String _rawStatus(WorkOrderEntity workOrder) {
    final statusEnum = workOrder.statusEnum?.trim();
    if (statusEnum != null && statusEnum.isNotEmpty) return statusEnum;
    return (workOrder.statusName ?? workOrder.status?.status ?? '').trim();
  }

  static String getLabel(WorkOrderEntity workOrder) {
    final raw = _rawStatus(workOrder);
    if (raw.isEmpty) return '-';
    return _labels[raw.toLowerCase()] ?? raw;
  }

  static Color getColor(WorkOrderEntity workOrder, AppColor appColor) {
    final raw = _rawStatus(workOrder);
    return _colors[raw.toLowerCase()] ??
        appColor.status[workOrder.status?.id ?? workOrder.statusId] ??
        appColor.primary[100]!;
  }
}
