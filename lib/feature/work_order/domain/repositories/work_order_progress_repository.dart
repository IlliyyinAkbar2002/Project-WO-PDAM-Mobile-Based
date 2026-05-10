import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';

abstract class WorkOrderProgressRepository {
  Future<DataState<List<WorkOrderProgressEntity>>> getProgressByWorkOrderId(
    int workOrderId,
  );
  Future<DataState<WorkOrderProgressEntity>> getWorkOrderProgressDetail(int id);
  Future<DataState<WorkOrderProgressEntity>> updateWorkOrderProgress(
    WorkOrderProgressModel workOrderProgress,
  );
}
