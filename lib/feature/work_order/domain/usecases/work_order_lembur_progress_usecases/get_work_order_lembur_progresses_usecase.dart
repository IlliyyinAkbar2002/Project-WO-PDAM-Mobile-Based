import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_lembur_repository.dart';

class GetLemburProgressByWorkOrderIdUsecase
    implements UseCase<Future<DataState<List<WorkOrderProgressEntity>>>, int> {
  final WorkOrderLemburRepository repository;

  GetLemburProgressByWorkOrderIdUsecase(this.repository);

  @override
  Future<DataState<List<WorkOrderProgressEntity>>> call(int workOrderId) {
    return repository.getProgressByWorkOrderId(workOrderId);
  }
}
