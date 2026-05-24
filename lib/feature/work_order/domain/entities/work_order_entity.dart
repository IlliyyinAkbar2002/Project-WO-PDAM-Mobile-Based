import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/assignment_workorder_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/location_type_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/status_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';

class WorkOrderEntity extends Equatable {
  final int? id;
  final String title;
  final DateTime? startDateTime;
  final int? duration;
  final String? durationUnit;
  final DateTime? endDateTime;
  final String? lokasiText; // Nama lokasi (text) untuk dikirim ke backend
  final int? creator;
  final int? statusId; //Mengambil dari Status
  final int? workOrderTypeId; //Mengambil dari WorkOrderType
  final int? splId;
  final int? locationTypeId; //Mengambil dari LocationType
  final bool requiresApproval;
  final LocationTypeEntity? locationType;
  final WorkOrderTypeEntity? workOrderType;
  final StatusEntity? status;
  final int? progresPersen;
  final DateTime? createdAt;

  /// Kategori form WO: 'meter' | 'jaringan' | 'infrastruktur'
  /// Diambil dari m_jenis_workorder.kategori_form via relasi jenis_workorder
  final String? kategoriForm;
  final Map<String, dynamic>? detailKategori;

  /// Prioritas WO sesuai BE enum: rendah | sedang | tinggi | darurat.
  /// Default `sedang` saat create kalau caller tidak set.
  final String? prioritas;

  /// Relasi ke entity assignment
  final AssignmentWorkorderEntity? assignment;
  final List<AssignmentWorkorderEntity>? assignments;

  const WorkOrderEntity({
    this.id,
    required this.title,
    this.startDateTime,
    this.duration,
    this.durationUnit,
    this.endDateTime,
    this.lokasiText,
    this.creator,
    this.statusId,
    this.workOrderTypeId,
    this.splId,
    this.locationTypeId,
    this.requiresApproval = false,
    this.locationType,
    this.workOrderType,
    this.status,
    this.progresPersen,
    this.createdAt,
    this.kategoriForm,
    this.detailKategori,
    this.prioritas,
    this.assignment,
    this.assignments,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    startDateTime,
    duration,
    durationUnit,
    endDateTime,
    lokasiText,
    creator,
    statusId,
    workOrderTypeId,
    splId,
    locationTypeId,
    requiresApproval,
    locationType,
    workOrderType,
    status,
    progresPersen,
    createdAt,
    kategoriForm,
    detailKategori,
    prioritas,
    assignment,
    assignments,
  ];

  WorkOrderEntity copyWith({
    int? id,
    String? title,
    DateTime? startDateTime,
    int? duration,
    String? durationUnit,
    DateTime? endDateTime,
    String? lokasiText,
    int? creator,
    int? statusId,
    int? workOrderTypeId,
    int? splId,
    int? locationTypeId,
    bool? requiresApproval,
    LocationTypeEntity? locationType,
    WorkOrderTypeEntity? workOrderType,
    StatusEntity? status,
    int? progresPersen,
    DateTime? createdAt,
    String? kategoriForm,
    Map<String, dynamic>? detailKategori,
    String? prioritas,
    AssignmentWorkorderEntity? assignment,
    List<AssignmentWorkorderEntity>? assignments,
  }) {
    return WorkOrderEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      startDateTime: startDateTime ?? this.startDateTime,
      duration: duration ?? this.duration,
      durationUnit: durationUnit ?? this.durationUnit,
      endDateTime: endDateTime ?? this.endDateTime,
      lokasiText: lokasiText ?? this.lokasiText,
      creator: creator ?? this.creator,
      statusId: statusId ?? this.statusId,
      workOrderTypeId: workOrderTypeId ?? this.workOrderTypeId,
      splId: splId ?? this.splId,
      locationTypeId: locationTypeId ?? this.locationTypeId,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      locationType: locationType ?? this.locationType,
      workOrderType: workOrderType ?? this.workOrderType,
      status: status ?? this.status,
      progresPersen: progresPersen ?? this.progresPersen,
      createdAt: createdAt ?? this.createdAt,
      kategoriForm: kategoriForm ?? this.kategoriForm,
      detailKategori: detailKategori ?? this.detailKategori,
      prioritas: prioritas ?? this.prioritas,
      assignment: assignment ?? this.assignment,
      assignments: assignments ?? this.assignments,
    );
  }
}
