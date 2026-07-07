import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/peminjaman_material_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/repository/material_repository.dart';

class PinjamMaterialParams {
  final int workOrderId;
  final String materialKode;
  final int jumlahPinjam;
  final String? catatan;

  PinjamMaterialParams({
    required this.workOrderId,
    required this.materialKode,
    required this.jumlahPinjam,
    this.catatan,
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
      materialKode: params.materialKode,
      jumlahPinjam: params.jumlahPinjam,
      catatan: params.catatan,
    );
  }
}
