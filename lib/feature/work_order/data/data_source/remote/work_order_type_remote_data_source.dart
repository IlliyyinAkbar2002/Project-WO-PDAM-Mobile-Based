import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_type_model.dart';

class WorkOrderTypeRemoteDataSource extends RemoteDatasource {
  WorkOrderTypeRemoteDataSource() : super();

  Future<DataState<List<WorkOrderTypeModel>>> fetchWorkOrderTypes() async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/jenis-workorder');
      final data = response.data['data']
          .map<WorkOrderTypeModel>((json) => WorkOrderTypeModel.fromMap(json))
          .toList();
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/jenis-workorder'),
        ),
      );
    }
  }

  Future<DataState<WorkOrderTypeModel>> fetchWorkOrderTypeDetail(int id) async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/jenis-workorder/$id');
      final data = WorkOrderTypeModel.fromMap(response.data);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/jenis-workorder/$id'),
        ),
      );
    }
  }

  // Future<DataState<WorkOrderTypeModel>> createWorkOrderType(
  //     WorkOrderTypeModel workOrderType) async {
  //   try {
  //     final response = await dio.post(
  //       '/work-order-types',
  //       data: workOrderType.toMap(),
  //     );
  //     final data = WorkOrderTypeModel.fromMap(response.data);
  //     return DataSuccess(data);
  //   } catch (e) {
  //     return DataFailed(DioException(
  //       error: e,
  //       requestOptions: RequestOptions(path: '/work-order-types'),
  //     ));
  //   }
  // }

  // Future<DataState<WorkOrderTypeModel>> updateWorkOrderType(
  //     WorkOrderTypeModel workOrderType) async {
  //   try {
  //     final response = await dio.put(
  //       '/work-order-types/${workOrderType.id}',
  //       data: workOrderType.toMap(),
  //     );
  //     final data = WorkOrderTypeModel.fromMap(response.data);
  //     return DataSuccess(data);
  //   } catch (e) {
  //     return DataFailed(DioException(
  //       error: e,
  //       requestOptions:
  //           RequestOptions(path: '/work-order-types/${workOrderType.id}'),
  //     ));
  //   }
  // }

  // Future<DataState<void>> deleteWorkOrderType(int id) async {
  //   try {
  //     await dio.delete('/work-order-types/$id');
  //     return DataSuccess(null);
  //   } catch (e) {
  //     return DataFailed(DioException(
  //       error: e,
  //       requestOptions: RequestOptions(path: '/work-order-types/$id'),
  //     ));
  //   }
  // }
}
