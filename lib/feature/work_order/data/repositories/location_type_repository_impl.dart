import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/location_type_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/location_type_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/location_type_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/location_type_repository.dart';

class LocationTypeRepositoryImpl implements LocationTypeRepository {
  final LocationTypeRemoteDataSource remoteDataSource;

  LocationTypeRepositoryImpl(this.remoteDataSource);

  @override
  Future<DataState<List<LocationTypeEntity>>> getLocationTypes() async {
    try {
      final response = await remoteDataSource.fetchLocationTypes();
      if (response is DataSuccess<List<LocationTypeModel>>) {
        final entities = response.data!
            .map((model) => model.toEntity())
            .toList();
        // for (var workOrder in response.data!) {
        //   await localDataSource.create(workOrder);
        // }
        return DataSuccess(entities);
      } else {
        return DataFailed(response.error!);
      }
    } catch (e) {
      return DataFailed("Terjadi kesalahan: $e");
    }
  }

  @override
  Future<DataState<LocationTypeEntity>> getLocationTypeDetail(int id) async {
    final response = await remoteDataSource.fetchLocationTypeDetail(id);
    if (response is DataSuccess<LocationTypeModel>) {
      final entity = response.data!.toEntity();
      return DataSuccess(entity);
    } else {
      return DataFailed(response.error!);
    }
  }
}
