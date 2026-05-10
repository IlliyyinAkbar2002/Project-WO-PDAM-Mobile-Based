import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/peminjaman_material_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repository/material_repository.dart';

class GetPeminjamanByWo implements UseCase<Future<DataState<List<PeminjamanMaterialEntity>>>, int> {
  final MaterialRepository _repository;
  GetPeminjamanByWo(this._repository);

  @override
  Future<DataState<List<PeminjamanMaterialEntity>>> call(int params) {
    return _repository.getPeminjamanByWo(params);
  }
}
