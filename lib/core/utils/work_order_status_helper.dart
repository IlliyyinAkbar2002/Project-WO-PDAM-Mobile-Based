import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/config/theme/app_color.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_entity.dart';

class WorkOrderStatusHelper {
  static String getLabel(WorkOrderEntity workOrder) {
    final statusEnum = workOrder.statusEnum?.trim();
    if (statusEnum == null || statusEnum.isEmpty) {
      final name = workOrder.statusName ?? workOrder.status?.status ?? '';
      if (name.toLowerCase() == 'pending') return 'Menunggu';
      if (name.toLowerCase() == 'proses' || name.toLowerCase() == 'in progress') return 'Dikerjakan';
      if (name.toLowerCase() == 'selesai') return 'Selesai';
      if (name.toLowerCase() == 'tutup') return 'Ditutup';
      if (name.toLowerCase() == 'ditolak') return 'Ditolak';
      return name.isEmpty ? '-' : name;
    }
    switch (statusEnum) {
      case 'Pending':
        return 'Menunggu';
      case 'Proses':
        return 'Dikerjakan';
      case 'Selesai':
        return 'Selesai';
      case 'Tutup':
        return 'Ditutup';
      case 'Ditolak':
        return 'Ditolak';
      default:
        return statusEnum;
    }
  }

  static Color getColor(WorkOrderEntity workOrder, AppColor appColor) {
    final statusEnum = workOrder.statusEnum?.trim();
    if (statusEnum == null || statusEnum.isEmpty) {
      final name = workOrder.statusName ?? workOrder.status?.status ?? '';
      if (name.toLowerCase() == 'pending') return const Color(0xFF94A3B8);
      if (name.toLowerCase() == 'proses' || name.toLowerCase() == 'in progress') return const Color(0xFF0EA5E9);
      if (name.toLowerCase() == 'selesai') return const Color(0xFF10B981);
      if (name.toLowerCase() == 'tutup') return const Color(0xFFEF4444);
      if (name.toLowerCase() == 'ditolak') return const Color(0xFFEF4444);
      return appColor.status[workOrder.status?.id ?? workOrder.statusId] ?? appColor.primary[100]!;
    }
    switch (statusEnum) {
      case 'Pending':
        return const Color(0xFF94A3B8); // Netral / Abu
      case 'Proses':
        return const Color(0xFF0EA5E9); // Biru
      case 'Selesai':
        return const Color(0xFF10B981); // Hijau
      case 'Tutup':
        return const Color(0xFFEF4444); // Merah
      case 'Ditolak':
        return const Color(0xFFEF4444);
      default:
        return appColor.status[workOrder.status?.id ?? workOrder.statusId] ?? appColor.primary[100]!;
    }
  }
}
