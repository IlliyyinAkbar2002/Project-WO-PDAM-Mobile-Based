import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/form_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/form_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/form_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/form_repository.dart';

class FormRepositoryImpl implements FormRepository {
  final FormRemoteDataSource remoteDataSource;
  // final ProgressDetailLocalDataSource localDataSource;

  FormRepositoryImpl(
    this.remoteDataSource,
    // this.localDataSource,
  );

  @override
  Future<DataState<List<FormEntity>>> getFormByWorkOrderTypeId(
    int workOrderTypeId,
  ) async {
    try {
      final response = await remoteDataSource.fetchProgressByWorkOrderTypeId(
        workOrderTypeId,
      );
      debugPrint("📥 Data dari RemoteDataSource: $response");
      if (response is DataSuccess<List<FormModel>>) {
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

  // @override
  // Future<DataState<FormEntity>> getFormDetail(int id) async {
  //   try {
  //     final response = await remoteDataSource.getFormDetail(id);
  //     debugPrint("📥 Data dari RemoteDataSource: $response");
  //     if (response is DataSuccess<FormModel>) {
  //       final entity = response.data!.toEntity();
  //       return DataSuccess(entity);
  //     } else {
  //       return DataFailed(response.error!);
  //     }
  //   } catch (e) {
  //     return DataFailed("Terjadi kesalahan: $e");
  //   }
  // }
}
