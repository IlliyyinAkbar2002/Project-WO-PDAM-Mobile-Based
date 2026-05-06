import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/material_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/peminjaman_material_entity.dart';

abstract class MaterialRepository {
  Future<DataState<List<MaterialEntity>>> getMasterMaterials();
  Future<DataState<List<PeminjamanMaterialEntity>>> getPeminjamanByWo(int workOrderId);
  Future<DataState<PeminjamanMaterialEntity>> pinjamMaterial({
    required int workOrderId,
    required int materialId,
    required int jumlahPinjam,
  });
  Future<DataState<PeminjamanMaterialEntity>> kembalikanMaterial({
    required int peminjamanId,
    required int jumlahKembali,
    String? kondisiKembali,
  });
}
