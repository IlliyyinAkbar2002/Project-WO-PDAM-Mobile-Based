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
  final int? tahapanTertinggi;
  // final int? departemenId;
  // final String? departemenNama;
  final bool? isActive;
  final int? assignedToPegawaiId;
  final String? statusName;
  final String? statusEnum;
  final String? kategoriForm;
  final Map<String, dynamic>? detailKategori;
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
    this.tahapanTertinggi,
    // this.departemenId,
    // this.departemenNama,
    this.isActive,
    this.assignedToPegawaiId,
    this.statusName,
    this.statusEnum,
  });

  bool get isLembur => splId != null;

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
    tahapanTertinggi,
    // departemenId,
    // departemenNama,
    isActive,
    assignedToPegawaiId,
    statusName,
    statusEnum,
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
    int? tahapanTertinggi,
    // int? departemenId,
    // String? departemenNama,
    bool? isActive,
    int? assignedToPegawaiId,
    String? statusName,
    String? statusEnum,
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
      tahapanTertinggi: tahapanTertinggi ?? this.tahapanTertinggi,
      // departemenId: departemenId ?? this.departemenId,
      // departemenNama: departemenNama ?? this.departemenNama,
      isActive: isActive ?? this.isActive,
      assignedToPegawaiId: assignedToPegawaiId ?? this.assignedToPegawaiId,
      statusName: statusName ?? this.statusName,
      statusEnum: statusEnum ?? this.statusEnum,
    );
  }
}
