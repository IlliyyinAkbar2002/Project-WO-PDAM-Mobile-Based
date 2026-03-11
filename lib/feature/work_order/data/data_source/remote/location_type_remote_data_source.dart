import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/location_type_model.dart';

class LocationTypeRemoteDataSource extends RemoteDatasource {
  LocationTypeRemoteDataSource() : super();

  Future<DataState<List<LocationTypeModel>>> fetchLocationTypes() async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/jenis-lokasi');
      final data = response.data
          .map<LocationTypeModel>((json) => LocationTypeModel.fromMap(json))
          .toList();
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/jenis-lokasi'),
        ),
      );
    }
  }

  Future<DataState<LocationTypeModel>> fetchLocationTypeDetail(int id) async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/jenis-lokasi/$id');
      final data = LocationTypeModel.fromMap(response.data);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/jenis-lokasi/$id'),
        ),
      );
    }
  }

  // Future<DataState<LocationTypeModel>> createLocationType(
  //     LocationTypeModel locationType) async {
  //   try {
  //     final response = await dio.post(
  //       '/jenis-lokasi',
  //       data: locationType.toMap(),
  //     );
  //     final data = LocationTypeModel.fromMap(response.data);
  //     return DataSuccess(data);
  //   } catch (e) {
  //     return DataFailed(DioException(
  //       error: e,
  //       requestOptions: RequestOptions(path: '/jenis-lokasi'),
  //     ));
  //   }
  // }

  // Future<DataState<LocationTypeModel>> updateLocationType(
  //     LocationTypeModel locationType) async {
  //   try {
  //     final response = await dio.put(
  //       '/jenis-lokasi/${locationType.id}',
  //       data: locationType.toMap(),
  //     );
  //     final data = LocationTypeModel.fromMap(response.data);
  //     return DataSuccess(data);
  //   } catch (e) {
  //     return DataFailed(DioException(
  //       error: e,
  //       requestOptions: RequestOptions(path: '/jenis-lokasi/${locationType.id}'),
  //     ));
  //   }
  // }
}
