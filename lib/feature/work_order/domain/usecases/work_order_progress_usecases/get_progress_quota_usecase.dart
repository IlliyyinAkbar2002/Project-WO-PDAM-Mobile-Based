import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_quota_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_progress_repository.dart';

/// Use case untuk mendapatkan kuota progress individual user yang sedang login.
///
/// Endpoint: GET /v1/progress-workorder/quota/{workorderId}
/// Response sekarang include `user_id` untuk tracking individual.
class GetProgressQuotaUseCase
    implements UseCase<Future<DataState<ProgressQuotaEntity>>, int> {
  final WorkOrderProgressRepository repository;

  GetProgressQuotaUseCase(this.repository);

  @override
  Future<DataState<ProgressQuotaEntity>> call(int workOrderId) {
    return repository.getProgressQuota(workOrderId);
  }
}
