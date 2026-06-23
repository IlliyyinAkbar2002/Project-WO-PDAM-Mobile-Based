import 'package:project_mobile_pdam/feature/work_order/domain/entities/form_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/location_type_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/master_location_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/spl_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';

import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_by_member_entity.dart';

import '/feature/work_order/domain/entities/work_order_entity.dart';

abstract class WorkOrderState {}

class WorkOrderInitial extends WorkOrderState {}

class WorkOrderLoading extends WorkOrderState {}

class WorkOrderLoaded extends WorkOrderState {
  final List<WorkOrderEntity> workOrders;

  WorkOrderLoaded(this.workOrders);
}

class WorkOrderDetailLoaded extends WorkOrderState {
  final WorkOrderEntity workOrder;

  WorkOrderDetailLoaded(this.workOrder);
}

class WorkOrderCreated extends WorkOrderState {
  final WorkOrderEntity workOrder;

  WorkOrderCreated(this.workOrder);
}

class WorkOrderUpdated extends WorkOrderState {
  final WorkOrderEntity workOrder;

  WorkOrderUpdated(this.workOrder);
}

class WorkOrderDeleted extends WorkOrderState {}

//work order type
class WorkOrderTypesLoaded extends WorkOrderState {
  final List<WorkOrderTypeEntity> workOrderTypes;

  WorkOrderTypesLoaded(this.workOrderTypes);
}

class WorkOrderTypeDetailLoaded extends WorkOrderState {
  final WorkOrderTypeEntity workOrderType;

  WorkOrderTypeDetailLoaded(this.workOrderType);
}

//location type
class LocationTypesLoaded extends WorkOrderState {
  final List<LocationTypeEntity> locationTypes;

  LocationTypesLoaded(this.locationTypes);
}

class LocationTypeDetailLoaded extends WorkOrderState {
  final LocationTypeEntity locationType;

  LocationTypeDetailLoaded(this.locationType);
}

//user
class UsersLoaded extends WorkOrderState {
  final List<UserEntity> users;

  UsersLoaded(this.users);
}

class UserDetailLoaded extends WorkOrderState {
  final UserEntity user;

  UserDetailLoaded(this.user);
}

//spl
class SplDetailLoaded extends WorkOrderState {
  final SplEntity spl;

  SplDetailLoaded(this.spl);
}

class SplCreated extends WorkOrderState {
  final SplEntity spl;

  SplCreated(this.spl);
}

class SplUpdated extends WorkOrderState {
  final SplEntity spl;

  SplUpdated(this.spl);
}

//progress
class ProgressesLoaded extends WorkOrderState {
  final List<WorkOrderProgressEntity> progresses;

  ProgressesLoaded(this.progresses);
}

class WorkOrderProgressDetailLoaded extends WorkOrderState {
  final WorkOrderProgressEntity progress;

  WorkOrderProgressDetailLoaded(this.progress);
}

class WorkOrderProgressUpdated extends WorkOrderState {
  final WorkOrderProgressEntity progress;

  WorkOrderProgressUpdated(this.progress);
}

class ProgressByMemberLoaded extends WorkOrderState {
  final ProgressByMemberEntity progressByMember;

  ProgressByMemberLoaded(this.progressByMember);
}

/// Error spesifik untuk load progress per-anggota agar tidak tertukar dengan
/// `WorkOrderError` generik (yang dipakai bersama oleh load detail/progress).
class ProgressByMemberError extends WorkOrderState {
  final String message;

  ProgressByMemberError(this.message);
}

//progress detail
class ProgressDetailsLoaded extends WorkOrderState {
  final List<ProgressDetailEntity> progressDetails;

  ProgressDetailsLoaded(this.progressDetails);
}

class ProgressDetailLoaded extends WorkOrderState {
  final ProgressDetailEntity progressDetail;

  ProgressDetailLoaded(this.progressDetail);
}

class ProgressDetailUpdated extends WorkOrderState {
  final ProgressDetailEntity progressDetail;

  ProgressDetailUpdated(this.progressDetail);
}

//form
class FormsLoaded extends WorkOrderState {
  final List<FormEntity> forms;

  FormsLoaded(this.forms);
}

//master location
class MasterLocationsLoaded extends WorkOrderState {
  final List<MasterLocationEntity> masterLocations;

  MasterLocationsLoaded(this.masterLocations);
}

class MasterLocationDetailLoaded extends WorkOrderState {
  final MasterLocationEntity masterLocation;

  MasterLocationDetailLoaded(this.masterLocation);
}

// Error handling
class WorkOrderError extends WorkOrderState {
  final String message;

  WorkOrderError(this.message);
}
