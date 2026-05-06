import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/material_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/material_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/peminjaman_material_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repository/material_repository.dart';

class MaterialRepositoryImpl implements MaterialRepository {
  final MaterialRemoteDataSource _remoteDataSource;

  MaterialRepositoryImpl(this._remoteDataSource);

  @override
  Future<DataState<List<MaterialEntity>>> getMasterMaterials() async {
    return await _remoteDataSource.getMasterMaterials();
  }

  @override
  Future<DataState<List<PeminjamanMaterialEntity>>> getPeminjamanByWo(int workOrderId) async {
    return await _remoteDataSource.getPeminjamanByWo(workOrderId);
  }

  @override
  Future<DataState<PeminjamanMaterialEntity>> pinjamMaterial({
    required int workOrderId,
    required int materialId,
    required int jumlahPinjam,
  }) async {
    return await _remoteDataSource.pinjamMaterial(
      workOrderId: workOrderId,
      materialId: materialId,
      jumlahPinjam: jumlahPinjam,
    );
  }

  @override
  Future<DataState<PeminjamanMaterialEntity>> kembalikanMaterial({
    required int peminjamanId,
    required int jumlahKembali,
    String? kondisiKembali,
  }) async {
    return await _remoteDataSource.kembalikanMaterial(
      peminjamanId: peminjamanId,
      jumlahKembali: jumlahKembali,
      kondisiKembali: kondisiKembali,
    );
  }
}
