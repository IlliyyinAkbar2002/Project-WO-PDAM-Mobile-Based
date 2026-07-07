import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/spl_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/spl_repository.dart';

class GetSplsUseCase
    implements UseCase<Future<DataState<List<SplEntity>>>, NoParams> {
  final SplRepository repository;

  GetSplsUseCase(this.repository);

  @override
  Future<DataState<List<SplEntity>>> call(NoParams params) {
    return repository.getSpls();
  }
}
