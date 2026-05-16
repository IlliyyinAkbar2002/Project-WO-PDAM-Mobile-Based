import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';


class WorkOrderActionRemoteDataSource extends RemoteDatasource {
  WorkOrderActionRemoteDataSource() : super();

  Future<DataState<Map<String, dynamic>>> createAction({
    required int workorderId,
    required int actionId,
    required DateTime waktuMulai,
    String? keterangan,
    int? sisaDurasiMenit,
    DateTime? estimasiSelesai,
  }) async {
    try {
      final payload = <String, dynamic>{
        'workorder_id': workorderId,
        'action_id': actionId,
        'waktu_mulai': waktuMulai.toIso8601String(),
        if (keterangan != null) 'keterangan': keterangan,
        if (sisaDurasiMenit != null) 'sisa_durasi_menit': sisaDurasiMenit,
        if (estimasiSelesai != null)
          'estimasi_selesai': estimasiSelesai.toIso8601String(),
      };

      final response = await post(
        path: '/v1/workorder-action',
        data: payload,
      );

      final dynamic data = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data)
          : response.data;

      return DataSuccess(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/workorder-action'),
        ),
      );
    }
  }

  Future<DataState<List<Map<String, dynamic>>>> fetchActions({
    int? workorderId,
  }) async {
    try {
      final response = await get(
        path: '/v1/workorder-action',
        queryParameters: {
          if (workorderId != null) 'workorder_id': workorderId,
        },
      );

      final dynamic raw = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data)
          : response.data;
      final List<Map<String, dynamic>> parsed = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];
      return DataSuccess(parsed);
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/workorder-action'),
        ),
      );
    }
  }
}
