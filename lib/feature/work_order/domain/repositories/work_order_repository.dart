import '/core/resource/data_state.dart';
import '/feature/work_order/domain/entities/work_order_entity.dart';

abstract class WorkOrderRepository {
  Future<DataState<List<WorkOrderEntity>>> getWorkOrders(
      int page,
      int limit,
      List<int>? status,
      List<int>? excludeStatus,
      int? picId,
      int? userId,
      int? type,
      String? dateRange,
      String? startDate,
      String? endDate,
      String? search,
      {bool fromHistory});
  Future<DataState<WorkOrderEntity>> getWorkOrderDetail(int id);
  Future<DataState<WorkOrderEntity>> createWorkOrder(WorkOrderEntity workOrder);
  Future<DataState<WorkOrderEntity>> updateWorkOrder(WorkOrderEntity workOrder);
  Future<DataState<void>> deleteWorkOrder(int id);
}
