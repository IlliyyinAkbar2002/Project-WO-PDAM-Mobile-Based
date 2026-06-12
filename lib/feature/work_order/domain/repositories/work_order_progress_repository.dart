import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_by_member_entity.dart';

abstract class WorkOrderProgressRepository {
  Future<DataState<List<WorkOrderProgressEntity>>> getProgressByWorkOrderId(
    int workOrderId,
  );
  Future<DataState<WorkOrderProgressEntity>> getWorkOrderProgressDetail(int id);
  Future<DataState<WorkOrderProgressEntity>> updateWorkOrderProgress(
    WorkOrderProgressModel workOrderProgress,
  );
  Future<DataState<WorkOrderProgressEntity>> resubmitProgress(
    WorkOrderProgressModel progress,
  );

  /// Mendapatkan progress individual setiap anggota tim (untuk SPV)
  Future<DataState<ProgressByMemberEntity>> getProgressByMember(int workOrderId);
}
