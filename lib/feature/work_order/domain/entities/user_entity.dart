import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/employee_entity.dart';

class UserEntity extends Equatable {
  final int? id;
  final int? employeeId;
  final int? roleId; // 'giver', 'receiver', 'both'
  final String? email;
  final EmployeeEntity? employee;

  const UserEntity({
    this.id,
    this.employeeId,
    this.roleId,
    this.email,
    this.employee,
  });

  @override
  List<Object?> get props => [id, employeeId, roleId, email, employee];

  UserEntity copyWith({
    int? id,
    int? employeeId,
    int? roleId,
    String? email,
    EmployeeEntity? employee,
  }) {
    return UserEntity(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      roleId: roleId ?? this.roleId,
      email: email ?? this.email,
      employee: employee ?? this.employee,
    );
  }
}
