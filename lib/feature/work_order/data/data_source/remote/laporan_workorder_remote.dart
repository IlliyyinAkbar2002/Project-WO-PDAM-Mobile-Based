import 'package:dio/dio.dart';
import '../../../../../core/resource/remote_data_source.dart';

abstract class LaporanWorkorderRemoteDataSource {
  Future<Response> createLaporanWorkorder(Map<String, dynamic> payload);
}

class LaporanWorkorderRemoteDataSourceImpl extends RemoteDatasource
    implements LaporanWorkorderRemoteDataSource {
  
  LaporanWorkorderRemoteDataSourceImpl() : super(baseEndPoint: '/api/v1');

  @override
  Future<Response> createLaporanWorkorder(Map<String, dynamic> payload) async {
    return await post(path: '/laporan-workorder', data: payload);
  }
}
