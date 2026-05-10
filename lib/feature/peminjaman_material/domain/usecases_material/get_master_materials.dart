import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/material_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/repository/material_repository.dart';

class GetMasterMaterials
    implements UseCase<Future<DataState<List<MaterialEntity>>>, NoParams> {
  final MaterialRepository _repository;
  GetMasterMaterials(this._repository);

  @override
  Future<DataState<List<MaterialEntity>>> call(NoParams params) {
    return _repository.getMasterMaterials();
  }
}
