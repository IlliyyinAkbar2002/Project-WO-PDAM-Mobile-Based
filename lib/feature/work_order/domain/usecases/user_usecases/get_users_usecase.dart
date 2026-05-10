import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/user_repository.dart';

class GetUsersParams extends Equatable {
  final int? departemenId;
  final List<int>? jabatanIds;

  const GetUsersParams({this.departemenId, this.jabatanIds});

  static const GetUsersParams empty = GetUsersParams();

  @override
  List<Object?> get props => [departemenId, jabatanIds];
}

class GetUsersUsecase
    implements UseCase<Future<DataState<List<UserEntity>>>, GetUsersParams> {
  final UserRepository repository;

  GetUsersUsecase(this.repository);

  @override
  Future<DataState<List<UserEntity>>> call(GetUsersParams params) {
    return repository.getUsers(
      departemenId: params.departemenId,
      jabatanIds: params.jabatanIds,
    );
  }
}
