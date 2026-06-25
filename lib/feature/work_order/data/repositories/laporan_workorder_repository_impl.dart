import 'package:dio/dio.dart';

import '../../../../core/resource/api_exception.dart';
import '../../../../core/resource/data_state.dart';
import '../data_source/remote/laporan_workorder_remote.dart';
import '../models/laporan_workorder_model.dart';
import '../../domain/repositories/laporan_workorder_repository.dart';

class LaporanWorkorderRepositoryImpl implements LaporanWorkorderRepository {
  final LaporanWorkorderRemoteDataSource remoteDataSource;

  LaporanWorkorderRepositoryImpl(this.remoteDataSource);

  @override
  Future<DataState<Response>> createLaporanWorkorder(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await remoteDataSource.createLaporanWorkorder(payload);
      return DataSuccess(response);
    } on ApiException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(ApiException(statusCode: 0, message: e.toString()));
    }
  }

  @override
  Future<DataState<LaporanReportModel>> getReportDetail(int workorderId) async {
    try {
      final response = await remoteDataSource.getReportDetail(workorderId);
      final body = response.data;
      final map = body is Map<String, dynamic>
          ? body
          : Map<String, dynamic>.from(body as Map);
      final report = LaporanReportModel.fromMap(map, workorderId: workorderId);
      return DataSuccess(report);
    } on ApiException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(ApiException(statusCode: 0, message: e.toString()));
    }
  }
}
