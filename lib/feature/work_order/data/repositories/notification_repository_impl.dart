import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/notification_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/notification_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/notification_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl(this.remoteDataSource);

  @override
  Future<DataState<List<NotificationEntity>>> getNotifications() async {
    try {
      final response = await remoteDataSource.fetchNotifications();
      if (response is DataSuccess<List<NotificationModel>>) {
        final entities = response.data!
            .map((model) => model.toEntity())
            .toList();
        return DataSuccess(entities);
      } else {
        return DataFailed(response.error!);
      }
    } catch (e) {
      return DataFailed("Gagal mengambil notifikasi: $e");
    }
  }

  @override
  Future<DataState<void>> markAsRead(String id) async {
    try {
      final response = await remoteDataSource.markAsRead(id);
      if (response is DataSuccess<void>) {
        return const DataSuccess(null);
      } else {
        return DataFailed(response.error!);
      }
    } catch (e) {
      return DataFailed("Gagal menandai notifikasi dibaca: $e");
    }
  }
}
