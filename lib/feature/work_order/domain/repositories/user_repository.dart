import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<DataState<List<UserEntity>>> getUsers();
  Future<DataState<UserEntity>> getUserDetail(int id);
}
