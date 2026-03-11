import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';

abstract class ProgressDetailRepository {
  Future<DataState<List<ProgressDetailEntity>>> getProgressDetails(
    int workOrderProgressId,
  );
  Future<DataState<ProgressDetailEntity>> getProgressDetail(int id);
  Future<DataState<ProgressDetailEntity>> updateProgressDetail(
    ProgressDetailEntity progressDetail,
  );
}
