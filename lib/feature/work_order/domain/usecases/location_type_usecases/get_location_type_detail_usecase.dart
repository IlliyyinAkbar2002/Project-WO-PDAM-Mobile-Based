import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/location_type_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/location_type_repository.dart';

class GetLocationTypeDetailUsecase
    implements UseCase<Future<DataState<LocationTypeEntity>>, int> {
  final LocationTypeRepository repository;

  GetLocationTypeDetailUsecase(this.repository);

  @override
  Future<DataState<LocationTypeEntity>> call(int id) {
    return repository.getLocationTypeDetail(id);
  }
}
