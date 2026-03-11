import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_type_repository.dart';

class GetWorkOrderTypesUsecase
    implements UseCase<Future<DataState<List<WorkOrderTypeEntity>>>, NoParams> {
  final WorkOrderTypeRepository repository;

  GetWorkOrderTypesUsecase(this.repository);

  @override
  Future<DataState<List<WorkOrderTypeEntity>>> call(NoParams params) {
    return repository.getWorkOrderTypes();
  }
}
