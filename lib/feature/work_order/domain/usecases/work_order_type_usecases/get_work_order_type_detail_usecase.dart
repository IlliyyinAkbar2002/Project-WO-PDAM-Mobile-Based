import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_type_repository.dart';

class GetWorkOrderTypeDetailUsecase
    implements UseCase<Future<DataState<WorkOrderTypeEntity>>, int> {
  final WorkOrderTypeRepository repository;

  GetWorkOrderTypeDetailUsecase(this.repository);

  @override
  Future<DataState<WorkOrderTypeEntity>> call(int id) {
    return repository.getWorkOrderTypeDetail(id);
  }
}
