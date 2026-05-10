import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/peminjaman_material_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/repository/material_repository.dart';

class PinjamMaterialParams {
  final int workOrderId;
  final int materialId;
  final int jumlahPinjam;

  PinjamMaterialParams({
    required this.workOrderId,
    required this.materialId,
    required this.jumlahPinjam,
  });
}

class PinjamMaterial
    implements
        UseCase<
          Future<DataState<PeminjamanMaterialEntity>>,
          PinjamMaterialParams
        > {
  final MaterialRepository _repository;
  PinjamMaterial(this._repository);

  @override
  Future<DataState<PeminjamanMaterialEntity>> call(
    PinjamMaterialParams params,
  ) {
    return _repository.pinjamMaterial(
      workOrderId: params.workOrderId,
      materialId: params.materialId,
      jumlahPinjam: params.jumlahPinjam,
    );
  }
}
