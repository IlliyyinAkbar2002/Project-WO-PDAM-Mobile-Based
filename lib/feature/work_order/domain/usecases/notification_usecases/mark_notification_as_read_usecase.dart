import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/notification_repository.dart';

class MarkNotificationAsReadUseCase implements UseCase<Future<DataState<void>>, String> {
  final NotificationRepository repository;

  MarkNotificationAsReadUseCase(this.repository);

  @override
  Future<DataState<void>> call(String params) {
    return repository.markAsRead(params);
  }
}
