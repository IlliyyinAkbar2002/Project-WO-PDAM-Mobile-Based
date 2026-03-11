import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/location_type_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/location_type_repository.dart';

class GetLocationTypesUsecase
    implements UseCase<Future<DataState<List<LocationTypeEntity>>>, NoParams> {
  final LocationTypeRepository repository;

  GetLocationTypesUsecase(this.repository);

  @override
  Future<DataState<List<LocationTypeEntity>>> call(NoParams params) {
    return repository.getLocationTypes();
  }
}
