import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/spl_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/spl_repository.dart';

class UpdateSplUseCase
    implements UseCase<Future<DataState<SplEntity>>, SplEntity> {
  final SplRepository repository;

  UpdateSplUseCase(this.repository);

  @override
  Future<DataState<SplEntity>> call(SplEntity spl) {
    return repository.updateSpl(spl);
  }
}
