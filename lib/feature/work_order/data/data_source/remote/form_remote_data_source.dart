import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/form_model.dart';

class FormRemoteDataSource extends RemoteDatasource {
  FormRemoteDataSource() : super();

  List<FormModel> _extractFormsPayload(dynamic raw) {
    final dynamic payload = raw is Map<String, dynamic>
        ? (raw['data'] ?? raw)
        : raw;

    if (payload is List) {
      return payload
          .whereType<Map>()
          .map<FormModel>(
            (json) => FormModel.fromMap(Map<String, dynamic>.from(json)),
          )
          .toList();
    }

    if (payload is Map<String, dynamic>) {
      if (payload.isEmpty) {
        return const <FormModel>[];
      }

      if (payload.containsKey('id') || payload.containsKey('nama_field')) {
        return [FormModel.fromMap(payload)];
      }

      if (payload['data'] != null) {
        return _extractFormsPayload(payload['data']);
      }
    }

    return const <FormModel>[];
  }

  Future<DataState<List<FormModel>>> fetchProgressByWorkOrderTypeId(
    int workOrderTypeId,
  ) async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(
        path: '/v1/detail-form',
        queryParameters: {'jenis_workorder_id': workOrderTypeId},
      );
      final data = _extractFormsPayload(response.data);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/detail-form'),
        ),
      );
    }
  }
}
