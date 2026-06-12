import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_progress_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/progress_by_member_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_by_member_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_progress_repository.dart';
import '/core/resource/data_state.dart';

class WorkOrderProgressRepositoryImpl implements WorkOrderProgressRepository {
  final WorkOrderProgressRemoteDataSource remoteDataSource;
  // final ProgressDetailLocalDataSource localDataSource;

  WorkOrderProgressRepositoryImpl(
    this.remoteDataSource,
    // this.localDataSource,
  );

  @override
  Future<DataState<List<WorkOrderProgressEntity>>> getProgressByWorkOrderId(
    int workOrderId,
  ) async {
    try {
      final response = await remoteDataSource.fetchProgressByWorkOrderId(
        workOrderId,
      );
      debugPrint("📥 Data dari RemoteDataSource: $response");
      if (response is DataSuccess<List<WorkOrderProgressModel>>) {
        final entities = response.data!
            .map((model) => model.toEntity())
            .toList();
        return DataSuccess(entities);
      } else {
        return DataFailed(response.error!);
      }
    } catch (e) {
      return DataFailed("Terjadi kesalahan: $e");
    }
  }

  @override
  Future<DataState<WorkOrderProgressEntity>> getWorkOrderProgressDetail(
    int id,
  ) async {
    try {
      final response = await remoteDataSource.getWorkOrderProgressDetail(id);
      debugPrint("📥 Data dari RemoteDataSource: $response");
      if (response is DataSuccess<WorkOrderProgressModel>) {
        return DataSuccess(response.data!.toEntity());
      } else {
        return DataFailed(response.error!);
      }
    } catch (e) {
      return DataFailed("Terjadi kesalahan: $e");
    }
  }

  @override
  Future<DataState<WorkOrderProgressEntity>> updateWorkOrderProgress(
    WorkOrderProgressModel workOrderProgress,
  ) async {
    try {
      // final model = WorkOrderProgressModel.fromEntity(workOrderProgress);
      final response = await remoteDataSource.updateWorkOrderProgressDetail(
        workOrderProgress,
      );
      debugPrint("📥 Data dari RemoteDataSource: $response");
      if (response is DataSuccess<WorkOrderProgressModel>) {
        return DataSuccess(response.data!.toEntity());
      } else {
        return DataFailed(response.error!);
      }
    } catch (e) {
      return DataFailed("Terjadi kesalahan: $e");
    }
  }

  @override
  Future<DataState<WorkOrderProgressEntity>> resubmitProgress(
    WorkOrderProgressModel progress,
  ) async {
    try {
      final response = await remoteDataSource.resubmitProgress(progress);
      debugPrint("📥 Resubmit response: $response");
      if (response is DataSuccess<WorkOrderProgressModel>) {
        return DataSuccess(response.data!.toEntity());
      } else {
        return DataFailed(response.error!);
      }
    } catch (e) {
      return DataFailed("Terjadi kesalahan: $e");
    }
  }

  @override
  Future<DataState<ProgressByMemberEntity>> getProgressByMember(
    int workOrderId,
  ) async {
    try {
      final response = await remoteDataSource.getProgressByMember(workOrderId);
      debugPrint("👥 Progress by member response: $response");
      if (response is DataSuccess<ProgressByMemberModel>) {
        return DataSuccess(response.data!.toEntity());
      } else {
        return DataFailed(response.error!);
      }
    } catch (e) {
      return DataFailed("Terjadi kesalahan: $e");
    }
  }
}
