import 'package:dio/dio.dart';

import '../../../../core/resource/api_exception.dart';
import '../../../../core/resource/data_state.dart';
import '../data_source/remote/laporan_workorder_remote.dart';
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
}
