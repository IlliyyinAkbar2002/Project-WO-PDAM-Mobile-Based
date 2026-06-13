import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/documentation_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';

class WorkOrderProgressEntity extends Equatable {
  final int? id;
  final int? order;
  final int? workOrderId;

  /// FK ke `m_tipe_progress` (lihat TKT-05). Sumber kebenaran untuk
  /// membedakan Mulai / Progress / Selesai.
  final int? tipeProgressId;

  /// FK ke `m_status` (lihat TKT-03). Draft / Submitted / Verified.
  final int? statusId;

  /// FK ke `users` (lihat TKT-04). Terisi setelah progres disubmit.
  final int? submittedByUserId;

  final String? description;
  final List<DocumentationEntity>? documentation;
  final DateTime? submitTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ProgressDetailEntity>? progressDetail;
  final int? tahapan;
  final Map<String, dynamic>? kategoriData;

  const WorkOrderProgressEntity({
    this.id,
    this.order,
    this.workOrderId,
    this.tipeProgressId,
    this.statusId,
    this.submittedByUserId,
    this.description,
    this.documentation,
    this.submitTime,
    this.createdAt,
    this.updatedAt,
    this.progressDetail,
    this.tahapan,
    this.kategoriData,
  });

  /// Backward-compat getter: UI Flutter lama masih membaca
  /// `progressType` sebagai String ("Mulai"/"Selesai"/"Progress N").
  /// Di-derive dari [tipeProgressId] + [order] agar tidak perlu
  /// merombak seluruh UI sekaligus.
  String? get progressType {
    if (tipeProgressId == null) return null;
    return TipeProgressId.label(tipeProgressId, order: order);
  }

  bool get isMulai => TipeProgressId.isMulai(tipeProgressId);
  bool get isSelesai => TipeProgressId.isSelesai(tipeProgressId);
  bool get isProgress => TipeProgressId.isProgress(tipeProgressId);
  bool get isInspeksi =>
      TipeProgressId.isInspeksi(tipeProgressId) || progressType == 'Inspeksi';

  bool get isDraft => ProgressStatusId.isDraft(statusId);
  bool get isSubmitted => ProgressStatusId.isSubmitted(statusId);
  bool get isVerified => ProgressStatusId.isVerified(statusId);
  bool get isRevisiRequested => ProgressStatusId.isRevisiRequested(statusId);
  bool get isDibatalkan => ProgressStatusId.isDibatalkan(statusId);

  bool get canCancel {
    if (!isSubmitted) return false;
    if (submitTime == null) return false;
    final elapsed = DateTime.now().toUtc().difference(submitTime!);
    return elapsed.inMinutes < 5;
  }

  @override
  List<Object?> get props => [
    id,
    order,
    workOrderId,
    tipeProgressId,
    statusId,
    submittedByUserId,
    description,
    documentation,
    submitTime,
    createdAt,
    updatedAt,
    progressDetail,
    tahapan,
    kategoriData,
  ];

  WorkOrderProgressEntity copyWith({
    int? id,
    int? order,
    int? workOrderId,
    int? tipeProgressId,
    int? statusId,
    int? submittedByUserId,
    String? description,
    List<DocumentationEntity>? documentation,
    DateTime? submitTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProgressDetailEntity>? progressDetail,
    int? tahapan,
    Map<String, dynamic>? kategoriData,
  }) {
    return WorkOrderProgressEntity(
      id: id ?? this.id,
      order: order ?? this.order,
      workOrderId: workOrderId ?? this.workOrderId,
      tipeProgressId: tipeProgressId ?? this.tipeProgressId,
      statusId: statusId ?? this.statusId,
      submittedByUserId: submittedByUserId ?? this.submittedByUserId,
      description: description ?? this.description,
      documentation: documentation ?? this.documentation,
      submitTime: submitTime ?? this.submitTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progressDetail: progressDetail ?? this.progressDetail,
      tahapan: tahapan ?? this.tahapan,
      kategoriData: kategoriData ?? this.kategoriData,
    );
  }
}
