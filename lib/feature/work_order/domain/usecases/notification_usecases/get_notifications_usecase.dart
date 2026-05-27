import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/notification_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/notification_repository.dart';

class GetNotificationsUseCase implements UseCase<Future<DataState<List<NotificationEntity>>>, void> {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  @override
  Future<DataState<List<NotificationEntity>>> call(void params) {
    return repository.getNotifications();
  }
}
