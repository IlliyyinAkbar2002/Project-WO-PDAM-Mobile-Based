import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_remote_data_source.dart';
import '/core/resource/data_state.dart';
import '/feature/work_order/data/models/work_order_model.dart';
import '/feature/work_order/domain/entities/work_order_entity.dart';
import '/feature/work_order/domain/repositories/work_order_repository.dart';

class WorkOrderRepositoryImpl implements WorkOrderRepository {
  final WorkOrderRemoteDataSource remoteDataSource;

  WorkOrderRepositoryImpl(this.remoteDataSource);

  @override
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
  ) async {
    try {
      final response = await remoteDataSource.fetchWorkOrders(
        page,
        limit,
        status,
        excludeStatus,
        picId,
        userId,
        type,
        dateRange,
        startDate,
        endDate,
        search,
      );
      debugPrint("📥 Data dari RemoteDataSource: $response");
      if (response is PaginatedDataSuccess<List<WorkOrderModel>>) {
        final entities = response.data!
            .map((model) => model.toEntity())
            .toList();
        return PaginatedDataSuccess(
          entities,
          totalPages: response.totalPages,
          currentPage: response.currentPage,
        );
      } else {
        return DataFailed(response.error!);
      }
    } catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<WorkOrderEntity>> getWorkOrderDetail(int id) async {
    final response = await remoteDataSource.fetchWorkOrderDetail(id);
    if (response is DataSuccess<WorkOrderModel>) {
      return DataSuccess(response.data!.toEntity());
    } else {
      return DataFailed(response.error!);
    }
  }

  @override
  Future<DataState<WorkOrderEntity>> createWorkOrder(
    WorkOrderEntity workOrder,
  ) async {
    try {
      final model = WorkOrderModel.fromEntity(workOrder);
      final response = await remoteDataSource.createWorkOrder(model);
      if (response is DataSuccess<WorkOrderModel>) {
        return DataSuccess(response.data!.toEntity());
      } else {
        return DataFailed("Gagal menyimpan work order ke server.");
      }
    } catch (e) {
      return DataFailed("Terjadi kesalahan saat menyimpan: $e");
    }
  }

  @override
  Future<DataState<WorkOrderEntity>> updateWorkOrder(
    WorkOrderEntity workOrder,
  ) async {
    final model = WorkOrderModel.fromEntity(workOrder);
    final response = await remoteDataSource.updateWorkOrder(model);
    if (response is DataSuccess<WorkOrderModel>) {
      return DataSuccess(response.data!.toEntity());
    } else {
      return DataFailed(response.error!);
    }
  }

  @override
  Future<DataState<void>> deleteWorkOrder(int id) async {
    final response = await remoteDataSource.deleteWorkOrder(id);
    if (response is DataSuccess) {
      return const DataSuccess(null);
    } else {
      return DataFailed(response.error!);
    }
  }
}
