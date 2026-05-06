import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/material_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repository/material_repository.dart';

class GetMasterMaterials implements UseCase<Future<DataState<List<MaterialEntity>>>, NoParams> {
  final MaterialRepository _repository;
  GetMasterMaterials(this._repository);

  @override
  Future<DataState<List<MaterialEntity>>> call(NoParams params) {
    return _repository.getMasterMaterials();
  }
}
