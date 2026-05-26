import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/spl_entity.dart';

abstract class SplRepository {
  Future<DataState<List<SplEntity>>> getSpls();
  Future<DataState<SplEntity>> getSplDetail(int id);
  Future<DataState<SplEntity>> updateSpl(SplEntity spl);
  Future<DataState<SplEntity>> createSpl(Map<String, dynamic> payload);
}
