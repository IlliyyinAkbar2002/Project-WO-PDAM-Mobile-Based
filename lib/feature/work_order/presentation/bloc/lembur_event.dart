import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';

abstract class LemburEvent extends Equatable {
  const LemburEvent();

  @override
  List<Object?> get props => [];
}

class GetLemburProgressByWorkOrderIdEvent extends LemburEvent {
  final int workOrderId;

  const GetLemburProgressByWorkOrderIdEvent(this.workOrderId);

  @override
  List<Object?> get props => [workOrderId];
}

class GetLemburProgressDetailEvent extends LemburEvent {
  final int id;

  const GetLemburProgressDetailEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class StartLemburProgressEvent extends LemburEvent {
  final WorkOrderProgressModel progress;

  const StartLemburProgressEvent(this.progress);

  @override
  List<Object?> get props => [progress];
}

class UpdateLemburProgressEvent extends LemburEvent {
  final WorkOrderProgressModel progress;

  const UpdateLemburProgressEvent(this.progress);

  @override
  List<Object?> get props => [progress];
}

class ResubmitLemburProgressEvent extends LemburEvent {
  final WorkOrderProgressModel progress;

  const ResubmitLemburProgressEvent(this.progress);

  @override
  List<Object?> get props => [progress];
}

class CancelLemburProgressEvent extends LemburEvent {
  final int progressId;

  const CancelLemburProgressEvent(this.progressId);

  @override
  List<Object?> get props => [progressId];
}

class GetLemburProgressByMemberEvent extends LemburEvent {
  final int workOrderId;

  const GetLemburProgressByMemberEvent(this.workOrderId);

  @override
  List<Object?> get props => [workOrderId];
}

class GetLemburProgressDetailsHistoryEvent extends LemburEvent {
  final int progressWorkorderId;

  const GetLemburProgressDetailsHistoryEvent(this.progressWorkorderId);

  @override
  List<Object?> get props => [progressWorkorderId];
}
