import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_type_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_type_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_type_repository.dart';

class WorkOrderTypeRepositoryImpl implements WorkOrderTypeRepository {
  final WorkOrderTypeRemoteDataSource remoteDataSource;

  WorkOrderTypeRepositoryImpl(this.remoteDataSource);

  @override
  Future<DataState<List<WorkOrderTypeEntity>>> getWorkOrderTypes() async {
    try {
      final response = await remoteDataSource.fetchWorkOrderTypes();
      if (response is DataSuccess<List<WorkOrderTypeModel>>) {
        final entities = response.data!
            .map((model) => model.toEntity())
            .toList();
        return DataSuccess(entities);
      } else {
        return DataFailed(response.error!);
      }
    } catch (e) {
      return DataFailed("Terjadi kesalahan: $e");
    }
  }

  @override
  Future<DataState<WorkOrderTypeEntity>> getWorkOrderTypeDetail(int id) async {
    final response = await remoteDataSource.fetchWorkOrderTypeDetail(id);
    if (response is DataSuccess<WorkOrderTypeModel>) {
      final entity = response.data!.toEntity();
      return DataSuccess(entity);
    } else {
      return DataFailed(response.error!);
    }
  }
}
