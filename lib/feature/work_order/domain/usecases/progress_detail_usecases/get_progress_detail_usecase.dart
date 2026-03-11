import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/progress_detail_repository.dart';

class GetProgressDetailUsecase
    implements UseCase<Future<DataState<ProgressDetailEntity>>, int> {
  final ProgressDetailRepository repository;

  GetProgressDetailUsecase(this.repository);

  @override
  Future<DataState<ProgressDetailEntity>> call(int id) {
    return repository.getProgressDetail(id);
  }
}
