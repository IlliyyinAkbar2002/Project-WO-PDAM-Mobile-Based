import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_entity.dart';

class WorkOrderKategoriHelper {
  const WorkOrderKategoriHelper._();

  static String? resolve(WorkOrderEntity workOrder) {
    return workOrder.kategoriForm ?? _inferFromType(workOrder);
  }

  /// Fallback: derive kategori dari nama workOrderType atau title WO.
  static String? _inferFromType(WorkOrderEntity workOrder) {
    final nama = workOrder.workOrderType?.name.toLowerCase() ?? '';
    final title = workOrder.title.toLowerCase();
    final combined = '$nama $title';
    if (combined.contains('pipa') ||
        combined.contains('jaringan') ||
        combined.contains('saluran') ||
        combined.contains('kebocoran')) {
      return 'jaringan';
    }
    if (combined.contains('pompa') ||
        combined.contains('reservoir') ||
        combined.contains('infrastruktur') ||
        combined.contains('aset') ||
        combined.contains('inspeksi') ||
        combined.contains('pemeliharaan')) {
      return 'infrastruktur';
    }
    if (combined.contains('meter') || combined.contains('kalibrasi')) {
      return 'meter';
    }
    return null;
  }
}
