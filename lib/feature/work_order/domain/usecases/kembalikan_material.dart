import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/peminjaman_material_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repository/material_repository.dart';

class KembalikanMaterialParams {
  final int peminjamanId;
  final int jumlahKembali;
  final String? kondisiKembali;

  KembalikanMaterialParams({
    required this.peminjamanId,
    required this.jumlahKembali,
    this.kondisiKembali,
  });
}

class KembalikanMaterial implements UseCase<Future<DataState<PeminjamanMaterialEntity>>, KembalikanMaterialParams> {
  final MaterialRepository _repository;
  KembalikanMaterial(this._repository);

  @override
  Future<DataState<PeminjamanMaterialEntity>> call(KembalikanMaterialParams params) {
    return _repository.kembalikanMaterial(
      peminjamanId: params.peminjamanId,
      jumlahKembali: params.jumlahKembali,
      kondisiKembali: params.kondisiKembali,
    );
  }
}
