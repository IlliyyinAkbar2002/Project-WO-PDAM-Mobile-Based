import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/form_model.dart';

class FormRemoteDataSource extends RemoteDatasource {
  FormRemoteDataSource() : super();

  Future<DataState<List<FormModel>>> fetchProgressByWorkOrderTypeId(
    int workOrderTypeId,
  ) async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(
        path: '/v1/detail-form',
        queryParameters: {'jenis_workorder_id': workOrderTypeId},
      );
      if (response.data is Map<String, dynamic>) {
        final progressModel = FormModel.fromMap(response.data);
        return DataSuccess([progressModel]); // Bungkus dalam List
      } else {
        // Jika response.data adalah List (opsional, untuk fleksibilitas)
        final data = (response.data as List)
            .map<FormModel>((json) => FormModel.fromMap(json))
            .toList();
        return DataSuccess(data);
      }
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
