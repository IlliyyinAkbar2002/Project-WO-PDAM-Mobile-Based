import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/progress_detail_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/progress_detail_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/progress_detail_repository.dart';
import '/core/resource/data_state.dart';

class ProgressDetailRepositoryImpl implements ProgressDetailRepository {
  final ProgressDetailRemoteDataSource remoteDataSource;
  // final ProgressDetailLocalDataSource localDataSource;

  ProgressDetailRepositoryImpl(
    this.remoteDataSource,
    // this.localDataSource,
  );

  @override
  Future<DataState<List<ProgressDetailEntity>>> getProgressDetails(
    int workOrderProgressId,
  ) async {
    try {
      final response = await remoteDataSource.fetchProgressDetails(
        workOrderProgressId,
      );
      debugPrint("📥 Data dari RemoteDataSource: $response");
      if (response is DataSuccess<List<ProgressDetailModel>>) {
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
  Future<DataState<ProgressDetailEntity>> getProgressDetail(int id) async {
    final response = await remoteDataSource.fetchProgressDetailDetail(id);
    if (response is DataSuccess<ProgressDetailModel>) {
      return DataSuccess(response.data!.toEntity());
    } else {
      return DataFailed(response.error!);
    }
  }

  @override
  Future<DataState<ProgressDetailEntity>> updateProgressDetail(
    ProgressDetailEntity progressDetail,
  ) async {
    try {
      final model = ProgressDetailModel.fromEntity(progressDetail);
      final response = await remoteDataSource.updateProgressDetail(model);
      if (response is DataSuccess<ProgressDetailModel>) {
        // await localDataSource.update(response.data!);
        return DataSuccess(response.data!.toEntity());
      } else {
        // final localResponse = await localDataSource.update(model);
        // if (localResponse is DataSuccess<ProgressDetailModel>) {
        //   return DataSuccess(localResponse.data!.toEntity());
        // } else {
        return DataFailed(response.error!);
        // }
      }
    } catch (e) {
      return DataFailed("Terjadi kesalahan: $e");
    }
  }
}
