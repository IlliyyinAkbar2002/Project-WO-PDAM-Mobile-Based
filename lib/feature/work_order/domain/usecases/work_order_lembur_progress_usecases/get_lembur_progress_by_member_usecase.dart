import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_by_member_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_lembur_repository.dart';

/// Use case untuk mendapatkan progress individual setiap anggota tim.
///
/// Endpoint: GET /v1/progress-workorder/by-member/{workorderId}
/// Digunakan oleh SPV untuk melihat kontribusi masing-masing anggota.
class GetLemburProgressByMemberUseCase
    implements UseCase<Future<DataState<ProgressByMemberEntity>>, int> {
  final WorkOrderLemburRepository repository;

  GetLemburProgressByMemberUseCase(this.repository);

  @override
  Future<DataState<ProgressByMemberEntity>> call(int workOrderId) {
    return repository.getProgressByMember(workOrderId);
  }
}
