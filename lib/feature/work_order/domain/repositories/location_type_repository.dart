import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/location_type_entity.dart';

abstract class LocationTypeRepository {
  Future<DataState<List<LocationTypeEntity>>> getLocationTypes();
  Future<DataState<LocationTypeEntity>> getLocationTypeDetail(int id);
}
