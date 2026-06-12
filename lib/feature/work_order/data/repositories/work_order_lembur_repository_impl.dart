import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_lembur_remote_data.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_by_member_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_lembur_repository.dart';

class WorkOrderLemburRepositoryImpl implements WorkOrderLemburRepository {
  final WorkOrderLemburRemoteDataSource _remoteDataSource;

  WorkOrderLemburRepositoryImpl(this._remoteDataSource);

  @override
  Future<DataState<List<WorkOrderProgressEntity>>> getProgressByWorkOrderId(
    int workOrderId,
  ) async {
    final response = await _remoteDataSource.fetchProgressByWorkOrderId(workOrderId);
    if (response is DataSuccess) {
      final entities = response.data!.map((model) => model.toEntity()).toList();
      return DataSuccess(entities);
    }
    return DataFailed(response.error!);
  }

  @override
  Future<DataState<WorkOrderProgressEntity>> getWorkOrderProgressDetail(
    int id,
  ) async {
    final response = await _remoteDataSource.getWorkOrderProgressDetail(id);
    if (response is DataSuccess) {
      return DataSuccess(response.data!.toEntity());
    }
    return DataFailed(response.error!);
  }

  @override
  Future<DataState<WorkOrderProgressEntity>> updateWorkOrderProgress(
    WorkOrderProgressModel workOrderProgress,
  ) async {
    final response = await _remoteDataSource.updateWorkOrderProgressDetail(
      workOrderProgress,
    );
    if (response is DataSuccess) {
      return DataSuccess(response.data!.toEntity());
    }
    return DataFailed(response.error!);
  }

  @override
  Future<DataState<WorkOrderProgressEntity>> resubmitProgress(
    WorkOrderProgressModel progress,
  ) async {
    final response = await _remoteDataSource.resubmitProgress(progress);
    if (response is DataSuccess) {
      return DataSuccess(response.data!.toEntity());
    }
    return DataFailed(response.error!);
  }

  @override
  Future<DataState<void>> cancelProgress(int progressId) async {
    return _remoteDataSource.cancelProgress(progressId);
  }

  @override
  Future<DataState<List<dynamic>>> getProgressDetailsHistory(
    int progressWorkorderId,
  ) async {
    return _remoteDataSource.getProgressDetailsHistory(progressWorkorderId);
  }

  @override
  Future<DataState<ProgressByMemberEntity>> getProgressByMember(
    int workOrderId,
  ) async {
    final response = await _remoteDataSource.getProgressByMember(workOrderId);
    if (response is DataSuccess) {
      return DataSuccess(response.data!.toEntity());
    }
    return DataFailed(response.error!);
  }
}
