import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_progress_repository.dart';

class GetProgressByWorkOrderIdUsecase
    implements UseCase<Future<DataState<List<WorkOrderProgressEntity>>>, int> {
  final WorkOrderProgressRepository repository;

  GetProgressByWorkOrderIdUsecase(this.repository);

  @override
  Future<DataState<List<WorkOrderProgressEntity>>> call(int workOrderId) {
    return repository.getProgressByWorkOrderId(workOrderId);
  }
}
