import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/master_location_model.dart';

class MasterLocationRemoteDataSource extends RemoteDatasource {
  MasterLocationRemoteDataSource() : super();

  Future<DataState<List<MasterLocationModel>>> fetchMasterLocations() async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/master-location');
      print("📥 Raw response from /v1/master-location: ${response.data}");
      print("📥 Response type: ${response.data.runtimeType}");

      // Laravel API returns: { "success": true, "data": [...], "user_location": {...} }
      // Extract the "data" field
      List<dynamic> responseList;

      if (response.data is Map<String, dynamic>) {
        print("📥 Response is a Map, extracting 'data' field");
        final Map<String, dynamic> responseMap =
            response.data as Map<String, dynamic>;

        if (responseMap['data'] == null) {
          print("❌ 'data' field is null in response");
          return const DataSuccess([]);
        }

        if (responseMap['data'] is! List) {
          print(
            "❌ 'data' field is not a List: ${responseMap['data'].runtimeType}",
          );
          return DataFailed(
            DioException(
              error: "Invalid response format: 'data' field is not a List",
              requestOptions: RequestOptions(path: '/v1/master-location'),
            ),
          );
        }

        responseList = responseMap['data'] as List<dynamic>;
      } else if (response.data is List) {
        // Fallback: direct array response
        print("📥 Response is a List (direct array)");
        responseList = response.data as List<dynamic>;
      } else {
        print("❌ Unexpected response type: ${response.data.runtimeType}");
        return DataFailed(
          DioException(
            error: "Invalid response format: expected Map or List",
            requestOptions: RequestOptions(path: '/v1/master-location'),
          ),
        );
      }

      print("📥 Total master locations: ${responseList.length}");

      // Check first item structure
      if (responseList.isNotEmpty) {
        print("📥 First location: ${responseList.first}");
      }

      // Parse each item
      final data = responseList
          .map<MasterLocationModel>((json) => MasterLocationModel.fromMap(json))
          .toList();

      print("✅ Successfully parsed ${data.length} master locations");
      return DataSuccess(data);
    } catch (e, stackTrace) {
      print("❌ Error fetching master locations: $e");
      print("❌ Stack trace: $stackTrace");
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/master-location'),
        ),
      );
    }
  }

  Future<DataState<MasterLocationModel>> fetchMasterLocationDetail(
    int id,
  ) async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/master-location/$id');
      final data = MasterLocationModel.fromMap(response.data);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/master-location/$id'),
        ),
      );
    }
  }
}
