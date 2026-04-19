import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/user_model.dart';

class UserRemoteDataSource extends RemoteDatasource {
  UserRemoteDataSource() : super();

  /// Fetch users with optional filters for department and position(s)
  ///
  /// [departemenId] - Optional department ID to filter by
  /// [jabatanIds] - Optional list of position IDs to filter by
  Future<DataState<List<UserModel>>> fetchUsers({
    int? departemenId,
    List<int>? jabatanIds,
  }) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {};

      if (departemenId != null) {
        queryParams['departemen_id'] = departemenId;
      }

      if (jabatanIds != null && jabatanIds.isNotEmpty) {
        // For array parameters, use 'jabatan_id[]' format
        queryParams['jabatan_id[]'] = jabatanIds;
      }

      // Use parent class's get() method which includes auth headers
      final response = await get(
        path: '/v1/pegawai/filter',
        queryParameters: queryParams,
      );
      print("📥 Raw response from /v1/pegawai/filter: ${response.data}");
      print("📥 Response type: ${response.data.runtimeType}");

      // The new endpoint wraps data in a 'data' field
      dynamic responseData = response.data;
      if (responseData is Map && responseData.containsKey('data')) {
        
        final dynamic meta = responseData['meta'];
        if (meta is Map) {
          print(
            "📥 /v1/pegawai/filter meta: allowed_jabatan_ids=${meta['allowed_jabatan_ids']}, "
            "caller_jabatan_id=${meta['caller_jabatan_id']}",
          );
        }
        responseData = responseData['data'];
      }

      // Check if response is a list
      if (responseData is! List) {
        print("❌ Expected List but got ${responseData.runtimeType}");
        return DataFailed(
          DioException(
            error: "Invalid response format: expected List",
            requestOptions: RequestOptions(path: '/v1/pegawai/filter'),
          ),
        );
      }

      final List<dynamic> responseList = responseData;
      print("📥 Total items: ${responseList.length}");

      // Check first item structure
      if (responseList.isNotEmpty) {
        print("📥 First item: ${responseList.first}");
        print("📥 First item type: ${responseList.first.runtimeType}");
        if (responseList.first is Map) {
          print(
            "📥 First item keys: ${(responseList.first as Map).keys.toList()}",
          );
        }
      }

      // Parse each item - the new endpoint already returns properly structured data
      final data = responseList.map<UserModel>((item) {
        print("🔍 Processing item from /v1/pegawai/filter: $item");
        print("🔍 Item type: ${item.runtimeType}");

        // The new endpoint already returns data with nested 'pegawai' field
        Map<String, dynamic> userMap = Map<String, dynamic>.from(item);

        print("🔍 Final userMap from /v1/pegawai/filter: $userMap");
        final userModel = UserModel.fromMap(userMap);
        print(
          "🔍 Parsed UserModel from /v1/pegawai/filter: id=${userModel.id}, name=${userModel.employee?.name}, nip=${userModel.employee?.nip}",
        );
        return userModel;
      }).toList();

      print(
        "✅ Successfully parsed ${data.length} users from /v1/pegawai/filter",
      );
      print(
        "✅ Sample result from /v1/pegawai/filter: ${data.isNotEmpty ? '${data.first.employee?.name} - ${data.first.employee?.nip}' : 'empty'}",
      );
      return DataSuccess(data);
    } catch (e, stackTrace) {
      print("❌ Error fetching pegawai from /v1/pegawai/filter: $e");
      print("❌ Stack trace from /v1/pegawai/filter: $stackTrace");
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/pegawai/filter'),
        ),
      );
    }
  }

  Future<DataState<UserModel>> fetchUserDetail(int id) async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/user/$id');
      final data = UserModel.fromMap(response.data);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/user/$id'),
        ),
      );
    }
  }
}
