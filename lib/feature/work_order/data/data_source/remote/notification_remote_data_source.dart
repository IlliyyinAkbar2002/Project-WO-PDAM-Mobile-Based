import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/notification_model.dart';

class NotificationRemoteDataSource extends RemoteDatasource {
  NotificationRemoteDataSource() : super();

  Future<DataState<List<NotificationModel>>> fetchNotifications() async {
    try {
      final response = await get(path: '/v1/notifications');
      
      final dynamic rawData = response.data;
      final dynamic dataField;
      if (rawData is Map && rawData.containsKey('data')) {
        dataField = rawData['data'];
      } else {
        dataField = rawData;
      }

      if (dataField is! List) {
        return DataFailed(
          DioException(
            error: "Format respon notifikasi tidak valid: harus berupa List",
            requestOptions: RequestOptions(path: '/v1/notifications'),
          ),
        );
      }

      final List<NotificationModel> notifications = dataField
          .map<NotificationModel>((json) => NotificationModel.fromMap(json as Map<String, dynamic>))
          .toList();

      return DataSuccess(notifications);
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/notifications'),
        ),
      );
    }
  }

  Future<DataState<void>> markAsRead(String id) async {
    try {
      await put(path: '/v1/notifications/$id/read');
      return const DataSuccess(null);
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/notifications/$id/read'),
        ),
      );
    }
  }
}
