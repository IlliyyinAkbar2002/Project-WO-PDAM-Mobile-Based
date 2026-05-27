import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<DataState<List<NotificationEntity>>> getNotifications();
  Future<DataState<void>> markAsRead(String id);
}
