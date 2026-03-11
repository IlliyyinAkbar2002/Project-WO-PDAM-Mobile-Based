import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';

abstract class WorkOrderTypeRepository {
  Future<DataState<List<WorkOrderTypeEntity>>> getWorkOrderTypes();
  Future<DataState<WorkOrderTypeEntity>> getWorkOrderTypeDetail(int id);
}
