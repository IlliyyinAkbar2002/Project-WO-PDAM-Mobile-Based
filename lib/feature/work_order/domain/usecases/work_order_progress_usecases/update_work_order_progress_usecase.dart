import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_progress_repository.dart';

class UpdateWorkOrderProgressUseCase
    implements
        UseCase<
          Future<DataState<WorkOrderProgressEntity>>,
          WorkOrderProgressModel
        > {
  final WorkOrderProgressRepository repository;

  UpdateWorkOrderProgressUseCase(this.repository);

  @override
  Future<DataState<WorkOrderProgressEntity>> call(
    WorkOrderProgressModel workOrderProgress,
  ) {
    return repository.updateWorkOrderProgress(workOrderProgress);
  }
}
