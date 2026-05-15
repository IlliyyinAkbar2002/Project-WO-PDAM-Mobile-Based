import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/master_location_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';

class AssignmentWorkorderEntity extends Equatable {
  final int? id;
  final int? workOrderId;
  final int? assigneeId;
  final UserEntity? assignee;
  final List<int>? assigneeIds;
  final List<UserEntity>? assignees;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final int? locationId;
  final MasterLocationEntity? location;
  final String? description;

  const AssignmentWorkorderEntity({
    this.id,
    this.workOrderId,
    this.assigneeId,
    this.assignee,
    this.assigneeIds,
    this.assignees,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.locationId,
    this.location,
    this.description,
  });

  @override
  List<Object?> get props => [
        id,
        workOrderId,
        assigneeId,
        assignee,
        assigneeIds,
        assignees,
        latitude,
        longitude,
        accuracy,
        locationId,
        location,
        description,
      ];

  AssignmentWorkorderEntity copyWith({
    int? id,
    int? workOrderId,
    int? assigneeId,
    UserEntity? assignee,
    List<int>? assigneeIds,
    List<UserEntity>? assignees,
    double? latitude,
    double? longitude,
    double? accuracy,
    int? locationId,
    MasterLocationEntity? location,
    String? description,
  }) {
    return AssignmentWorkorderEntity(
      id: id ?? this.id,
      workOrderId: workOrderId ?? this.workOrderId,
      assigneeId: assigneeId ?? this.assigneeId,
      assignee: assignee ?? this.assignee,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      assignees: assignees ?? this.assignees,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      locationId: locationId ?? this.locationId,
      location: location ?? this.location,
      description: description ?? this.description,
    );
  }
}
