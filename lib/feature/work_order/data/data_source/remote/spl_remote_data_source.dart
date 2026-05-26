import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/spl_model.dart';

class SplRemoteDataSource extends RemoteDatasource {
  SplRemoteDataSource() : super();

  Future<DataState<List<SplModel>>> fetchSpls() async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/lembur-spl');
      final data = response.data['data']
          .map<SplModel>((json) => SplModel.fromMap(json))
          .toList();
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/lembur-spl'),
        ),
      );
    }
  }

  Future<DataState<SplModel>> fetchSplDetail(int id) async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/lembur-spl/$id');
      final data = SplModel.fromMap(response.data);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/lembur-spl/$id'),
        ),
      );
    }
  }

  /// Create a new lembur SPL (POST /v1/lembur-spl).
  /// Payload contract (per BE):
  /// - judul_pekerjaan, jenis_pekerjaan, tanggal_lembur (yyyy-MM-dd),
  ///   jam_mulai (HH:mm), estimasi_jam (int), alasan_lembur,
  ///   members: `List<int>` user ids
  /// `pemohon_id` and `status_id` are auto-filled by the server.
  Future<DataState<SplModel>> createSpl(Map<String, dynamic> payload) async {
    try {
      final response = await post(path: '/v1/lembur-spl', data: payload);
      // BE may return either { data: {...} } or the resource directly.
      final raw = response.data;
      final Map<String, dynamic> map = (raw is Map && raw['data'] is Map)
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : Map<String, dynamic>.from(raw as Map);
      return DataSuccess(SplModel.fromMap(map));
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/lembur-spl'),
        ),
      );
    }
  }

  Future<DataState<SplModel>> updateSpl(SplModel spl) async {
    try {
      // Use parent class's put() method which includes auth headers
      final response = await put(
        path: '/v1/lembur-spl/${spl.id}',
        data: spl.toMap(),
      );
      final data = SplModel.fromMap(response.data);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/lembur-spl/${spl.id}'),
        ),
      );
    }
  }
}
