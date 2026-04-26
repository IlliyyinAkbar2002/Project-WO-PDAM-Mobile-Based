import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/progress_detail_model.dart';

class ProgressDetailRemoteDataSource extends RemoteDatasource {
  ProgressDetailRemoteDataSource() : super();

  List<ProgressDetailModel> _extractProgressDetails(dynamic raw) {
    final dynamic payload = raw is Map<String, dynamic> ? (raw['data'] ?? raw) : raw;

    if (payload is List) {
      return payload
          .whereType<Map>()
          .map<ProgressDetailModel>(
            (json) => ProgressDetailModel.fromMap(Map<String, dynamic>.from(json)),
          )
          .toList();
    }

    if (payload is Map<String, dynamic>) {
      if (payload.isEmpty) return const <ProgressDetailModel>[];

      // Jika backend mengirim map tunggal detail-progress.
      if (payload.containsKey('id') || payload.containsKey('detail_form_id')) {
        return [ProgressDetailModel.fromMap(payload)];
      }

      // Jika ternyata ada nested data lagi.
      if (payload['data'] is List || payload['data'] is Map<String, dynamic>) {
        return _extractProgressDetails(payload['data']);
      }
    }

    return const <ProgressDetailModel>[];
  }

  Future<DataState<List<ProgressDetailModel>>> fetchProgressDetails(
    int workOrderProgressId,
  ) async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(
        path: '/v1/detail-progress',
        queryParameters: {'progress_workorder_id': workOrderProgressId},
      );
      final data = _extractProgressDetails(response.data);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/detail-progress'),
        ),
      );
    }
  }

  Future<DataState<ProgressDetailModel>> fetchProgressDetailDetail(
    int id,
  ) async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/detail-progress/$id');
      final data = ProgressDetailModel.fromMap(response.data);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/detail-progress/$id'),
        ),
      );
    }
  }

  Future<DataState<ProgressDetailModel>> updateProgressDetail(
    ProgressDetailModel progressDetail,
  ) async {
    try {
      // Use parent class's put() method which includes auth headers
      final response = await put(
        path: '/v1/detail-progress/${progressDetail.id}',
        data: progressDetail.toMap(),
      );
      final data = ProgressDetailModel.fromMap(response.data);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(
            path: '/v1/detail-progress/${progressDetail.id}',
          ),
        ),
      );
    }
  }
}
