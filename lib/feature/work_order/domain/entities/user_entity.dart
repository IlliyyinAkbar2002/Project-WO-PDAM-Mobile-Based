import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/employee_entity.dart';

class UserEntity extends Equatable {
  final int? id;
  final int? employeeId;
  final int? roleId; // 'giver', 'receiver', 'both'
  final String? email;
  final EmployeeEntity? employee;

  /// `true` bila pegawai ini masih memegang WO yang belum selesai, sehingga
  /// tidak boleh di-assign ke WO lain. Diisi oleh `/v1/pegawai/filter`
  /// (`is_busy`). Default `false` supaya FE tetap jalan bila backend belum
  /// mengirim field ini — hard block di backend tetap jadi penentu akhir.
  final bool isBusy;

  /// WO yang menahan pegawai ini, untuk ditampilkan sebagai alasan di UI.
  final int? busyWorkorderId;
  final String? busyWorkorderName;

  const UserEntity({
    this.id,
    this.employeeId,
    this.roleId,
    this.email,
    this.employee,
    this.isBusy = false,
    this.busyWorkorderId,
    this.busyWorkorderName,
  });

  @override
  List<Object?> get props => [
    id,
    employeeId,
    roleId,
    email,
    employee,
    isBusy,
    busyWorkorderId,
    busyWorkorderName,
  ];

  UserEntity copyWith({
    int? id,
    int? employeeId,
    int? roleId,
    String? email,
    EmployeeEntity? employee,
    bool? isBusy,
    int? busyWorkorderId,
    String? busyWorkorderName,
  }) {
    return UserEntity(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      roleId: roleId ?? this.roleId,
      email: email ?? this.email,
      employee: employee ?? this.employee,
      isBusy: isBusy ?? this.isBusy,
      busyWorkorderId: busyWorkorderId ?? this.busyWorkorderId,
      busyWorkorderName: busyWorkorderName ?? this.busyWorkorderName,
    );
  }
}
