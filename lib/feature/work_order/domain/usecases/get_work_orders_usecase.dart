import '/core/resource/data_state.dart';
import '/feature/work_order/domain/entities/work_order_entity.dart';
import '/feature/work_order/domain/repositories/work_order_repository.dart';
import '/core/usecase/usecase.dart';

class GetWorkOrdersUseCase
    implements
        UseCase<Future<DataState<List<WorkOrderEntity>>>, WorkOrderParams> {
  final WorkOrderRepository repository;

  GetWorkOrdersUseCase(this.repository);

  @override
  Future<DataState<List<WorkOrderEntity>>> call(WorkOrderParams params) {
    return repository.getWorkOrders(
      params.page,
      params.limit,
      params.status,
      params.excludeStatus,
      params.picId,
      params.userId,
      params.type,
      params.dateRange,
      params.startDate,
      params.endDate,
      params.search,
      fromHistory: params.fromHistory,
    );
  }
}

class WorkOrderParams {
  final int page;
  final int limit;
  // Optional parameters
  final List<int>? status;
  final List<int>? excludeStatus;
  final int? picId;
  final int? userId;
  final int? type;
  final String? dateRange;
  final String? startDate;
  final String? endDate;
  final String? search;

  /// Bila true, ambil dari endpoint `/v1/workorder/history` (eager-load laporan)
  /// alih-alih index `/v1/workorder`. Default false → perilaku lama.
  final bool fromHistory;

  // Constructor
  WorkOrderParams(
      {required this.page,
      required this.limit,
      this.status,
      this.excludeStatus,
      this.picId,
      this.userId,
      this.type,
      this.dateRange,
      this.startDate,
      this.endDate,
      this.search,
      this.fromHistory = false});
}
