import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/spl_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/spl_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/spl_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/spl_repository.dart';

class SplRepositoryImpl implements SplRepository {
  final SplRemoteDataSource remoteDataSource;
  // final SplLocalDataSource localDataSource;

  SplRepositoryImpl(
    this.remoteDataSource,
    // this.localDataSource,
  );

  @override
  Future<DataState<List<SplEntity>>> getSpls() async {
    try {
      final response = await remoteDataSource.fetchSpls();
      debugPrint("📥 Data dari RemoteDataSource: $response");
      if (response is DataSuccess<List<SplModel>>) {
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
  Future<DataState<SplEntity>> getSplDetail(int id) async {
    final response = await remoteDataSource.fetchSplDetail(id);
    if (response is DataSuccess<SplModel>) {
      return DataSuccess(response.data!.toEntity());
    } else {
      return DataFailed(response.error!);
    }
  }

  @override
  Future<DataState<SplEntity>> updateSpl(SplEntity spl) async {
    try {
      final model = SplModel.fromEntity(spl);
      final response = await remoteDataSource.updateSpl(model);
      if (response is DataSuccess<SplModel>) {
        return DataSuccess(response.data!.toEntity());
      } else {
        return DataFailed(response.error!);
      }
    } catch (e) {
      return DataFailed("Terjadi kesalahan: $e");
    }
  }

  @override
  Future<DataState<SplEntity>> createSpl(Map<String, dynamic> payload) async {
    try {
      final response = await remoteDataSource.createSpl(payload);
      if (response is DataSuccess<SplModel>) {
        return DataSuccess(response.data!.toEntity());
      } else {
        return DataFailed(response.error!);
      }
    } catch (e) {
      return DataFailed("Terjadi kesalahan: $e");
    }
  }
}
