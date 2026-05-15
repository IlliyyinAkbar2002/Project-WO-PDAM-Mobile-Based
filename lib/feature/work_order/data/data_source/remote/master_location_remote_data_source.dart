import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/master_location_model.dart';

class MasterLocationRemoteDataSource extends RemoteDatasource {
  MasterLocationRemoteDataSource() : super();

  Future<DataState<List<MasterLocationModel>>> fetchMasterLocations() async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/master-location');
      debugPrint("📥 Raw response from /v1/master-location: ${response.data}");
      debugPrint("📥 Response type: ${response.data.runtimeType}");

      // Laravel API returns: { "success": true, "data": [...], "user_location": {...} }
      // Extract the "data" field
      List<dynamic> responseList;

      if (response.data is Map<String, dynamic>) {
        debugPrint("📥 Response is a Map, extracting 'data' field");
        final Map<String, dynamic> responseMap =
            response.data as Map<String, dynamic>;

        if (responseMap['data'] == null) {
          debugPrint("❌ 'data' field is null in response");
          return const DataSuccess([]);
        }

        if (responseMap['data'] is! List) {
          debugPrint(
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
        debugPrint("📥 Response is a List (direct array)");
        responseList = response.data as List<dynamic>;
      } else {
        debugPrint("❌ Unexpected response type: ${response.data.runtimeType}");
        return DataFailed(
          DioException(
            error: "Invalid response format: expected Map or List",
            requestOptions: RequestOptions(path: '/v1/master-location'),
          ),
        );
      }

      debugPrint("📥 Total master locations: ${responseList.length}");

      // Check first item structure
      if (responseList.isNotEmpty) {
        debugPrint("📥 First location: ${responseList.first}");
      }

      // Parse each item
      final data = responseList
          .map<MasterLocationModel>((json) => MasterLocationModel.fromMap(json))
          .toList();

      debugPrint("✅ Successfully parsed ${data.length} master locations");
      return DataSuccess(data);
    } catch (e, stackTrace) {
      debugPrint("❌ Error fetching master locations: $e");
      debugPrint("❌ Stack trace: $stackTrace");
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
    } catch (e, stackTrace) {
      debugPrint("❌ Error fetching master location detail: $e");
      debugPrint("❌ Stack trace: $stackTrace");
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/master-location/$id'),
        ),
      );
    }
  }
}
