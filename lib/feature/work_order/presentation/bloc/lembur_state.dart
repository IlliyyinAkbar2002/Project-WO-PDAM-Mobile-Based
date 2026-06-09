import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_by_member_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_quota_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';

abstract class LemburState extends Equatable {
  const LemburState();

  @override
  List<Object?> get props => [];
}

class LemburInitial extends LemburState {}

class LemburLoading extends LemburState {}

class LemburError extends LemburState {
  final String message;

  const LemburError(this.message);

  @override
  List<Object?> get props => [message];
}

class LemburProgressesLoaded extends LemburState {
  final List<WorkOrderProgressEntity> progresses;

  const LemburProgressesLoaded(this.progresses);

  @override
  List<Object?> get props => [progresses];
}

class LemburProgressDetailLoaded extends LemburState {
  final WorkOrderProgressEntity progress;

  const LemburProgressDetailLoaded(this.progress);

  @override
  List<Object?> get props => [progress];
}

class LemburProgressUpdated extends LemburState {
  final WorkOrderProgressEntity progress;

  const LemburProgressUpdated(this.progress);

  @override
  List<Object?> get props => [progress];
}

class LemburProgressQuotaLoaded extends LemburState {
  final ProgressQuotaEntity quota;

  const LemburProgressQuotaLoaded(this.quota);

  @override
  List<Object?> get props => [quota];
}

class LemburProgressByMemberLoaded extends LemburState {
  final ProgressByMemberEntity progressByMember;

  const LemburProgressByMemberLoaded(this.progressByMember);

  @override
  List<Object?> get props => [progressByMember];
}

class LemburCancelProgressSuccess extends LemburState {}

class LemburProgressDetailsHistoryLoaded extends LemburState {
  final List<dynamic> details;

  const LemburProgressDetailsHistoryLoaded(this.details);

  @override
  List<Object?> get props => [details];
}
