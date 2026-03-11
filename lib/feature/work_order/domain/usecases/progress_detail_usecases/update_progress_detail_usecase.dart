import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/progress_detail_repository.dart';

class UpdateProgressDetailUseCase
    implements
        UseCase<Future<DataState<ProgressDetailEntity>>, ProgressDetailEntity> {
  final ProgressDetailRepository repository;

  UpdateProgressDetailUseCase(this.repository);

  @override
  Future<DataState<ProgressDetailEntity>> call(
    ProgressDetailEntity progressDetail,
  ) {
    return repository.updateProgressDetail(progressDetail);
  }
}
