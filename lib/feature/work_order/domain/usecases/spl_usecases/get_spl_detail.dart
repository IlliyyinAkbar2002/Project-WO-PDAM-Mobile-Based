import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/spl_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/spl_repository.dart';

class GetSplDetailUseCase
    implements UseCase<Future<DataState<SplEntity>>, int> {
  final SplRepository repository;

  GetSplDetailUseCase(this.repository);

  @override
  Future<DataState<SplEntity>> call(int id) {
    return repository.getSplDetail(id);
  }
}
