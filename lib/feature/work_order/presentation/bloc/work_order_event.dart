import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/spl_entity.dart';

import '/feature/work_order/domain/entities/work_order_entity.dart';

abstract class WorkOrderEvent {}

class GetWorkOrdersEvent extends WorkOrderEvent {
  final List<int>? status;
  final List<int>? excludeStatus;
  final int? picId;
  final int? userId;
  final int? type;
  final String? dateRange;
  final String? startDate;
  final String? endDate;
  final String? search;

  /// Filter FE-side (BE belum mendukungnya). Bila di-set, daftar WO hanya
  /// menampilkan WO yang `assigned_to`-nya pegawai ini. Lihat WorkOrderBloc.
  final int? assignedToPegawaiId;

  /// Filter FE-side berdasar departemen pemilik WO.
  final int? departemenId;

  /// Bila true, WO dengan `is_active == false` disembunyikan (FE-side).
  final bool? onlyActive;

  /// Filter FE-side berdasar `status` string BE (case-insensitive). Hanya WO
  /// dengan status di daftar ini yang ditampilkan (mis. ['Pending'] untuk WO
  /// Masuk). Null = tidak memfilter.
  final List<String>? includeStatusNames;

  /// Kebalikan: WO dengan status di daftar ini disembunyikan (mis. ['Pending']
  /// untuk WO Keluar). Null = tidak memfilter.
  final List<String>? excludeStatusNames;

  GetWorkOrdersEvent({
    this.status,
    this.excludeStatus,
    this.picId,
    this.userId,
    this.type,
    this.dateRange,
    this.startDate,
    this.endDate,
    this.search,
    this.assignedToPegawaiId,
    this.departemenId,
    this.onlyActive,
    this.includeStatusNames,
    this.excludeStatusNames,
  });
}

class LoadMoreWorkOrdersEvent extends WorkOrderEvent {
  final int page;
  final int limit;
  final List<int>? status;
  final List<int>? excludeStatus;
  final int? picId;
  final int? userId;
  final int? type;
  final String? dateRange;
  final String? startDate;
  final String? endDate;
  final int? assignedToPegawaiId;
  final int? departemenId;
  final bool? onlyActive;
  final List<String>? includeStatusNames;
  final List<String>? excludeStatusNames;

  LoadMoreWorkOrdersEvent(
    this.page,
    this.limit, {
    this.status,
    this.excludeStatus,
    this.picId,
    this.userId,
    this.type,
    this.dateRange,
    this.startDate,
    this.endDate,
    this.assignedToPegawaiId,
    this.departemenId,
    this.onlyActive,
    this.includeStatusNames,
    this.excludeStatusNames,
  });
}

class SearchWorkOrdersEvent extends WorkOrderEvent {
  final String query;
  final List<int>? status;
  final List<int>? excludeStatus;
  final int? picId;
  final int? userId;
  final int? type;
  final String? dateRange;
  final String? startDate;
  final String? endDate;
  final int? assignedToPegawaiId;
  final int? departemenId;
  final bool? onlyActive;
  final List<String>? includeStatusNames;
  final List<String>? excludeStatusNames;

  SearchWorkOrdersEvent(
    this.query, {
    this.status,
    this.excludeStatus,
    this.picId,
    this.userId,
    this.type,
    this.dateRange,
    this.startDate,
    this.endDate,
    this.assignedToPegawaiId,
    this.departemenId,
    this.onlyActive,
    this.includeStatusNames,
    this.excludeStatusNames,
  });
}

class GetWorkOrderDetailEvent extends WorkOrderEvent {
  final int id;

  GetWorkOrderDetailEvent(this.id);
}

/// Push an already-fetched WO entity directly into [WorkOrderDetailLoaded]
/// state without making a network call. Dipakai mis. setelah `assignStaff`
/// yang mengembalikan workorder lengkap di response body.
class SetWorkOrderDetailEvent extends WorkOrderEvent {
  final WorkOrderEntity workOrder;

  SetWorkOrderDetailEvent(this.workOrder);
}

class CreateWorkOrderEvent extends WorkOrderEvent {
  final WorkOrderEntity workOrder;

  CreateWorkOrderEvent(this.workOrder);
}

class UpdateWorkOrderEvent extends WorkOrderEvent {
  final WorkOrderEntity workOrder;

  UpdateWorkOrderEvent(this.workOrder);
}

class DeleteWorkOrderEvent extends WorkOrderEvent {
  final int id;

  DeleteWorkOrderEvent(this.id);
}

//work order type
class GetWorkOrderTypesEvent extends WorkOrderEvent {}

class GetWorkOrderTypeDetailEvent extends WorkOrderEvent {
  final int id;

  GetWorkOrderTypeDetailEvent(this.id);
}

//location type
class GetLocationTypesEvent extends WorkOrderEvent {}

class GetLocationTypeDetailEvent extends WorkOrderEvent {
  final int id;

  GetLocationTypeDetailEvent(this.id);
}

//user
class GetUsersEvent extends WorkOrderEvent {
  /// Filter opsional berdasar departemen. Null = tidak memfilter.
  final int? departemenId;

  /// Filter opsional daftar jabatan yang boleh dipilih. Server akan
  /// melakukan clamp terhadap hirarki user yang login, sehingga FE
  /// aman mengirim superset; id di luar izin akan di-discard backend.
  final List<int>? jabatanIds;

  GetUsersEvent({this.departemenId, this.jabatanIds});
}

class GetUserDetailEvent extends WorkOrderEvent {
  final int id;

  GetUserDetailEvent(this.id);
}

//spl
class GetSplDetailEvent extends WorkOrderEvent {
  final int id;

  GetSplDetailEvent(this.id);
}

class CreateSplEvent extends WorkOrderEvent {
  /// Map payload sesuai kontrak BE: judul_pekerjaan, jenis_workorder_id,
  /// tanggal_lembur (yyyy-MM-dd), jam_mulai (HH:mm), estimasi_jam,
  /// alasan_lembur, members (`List<int>`).
  final Map<String, dynamic> payload;

  CreateSplEvent(this.payload);
}

class UpdateSplEvent extends WorkOrderEvent {
  final SplEntity spl;

  UpdateSplEvent(this.spl);
}

//progress
class GetProgressByWorkOrderIdEvent extends WorkOrderEvent {
  final int workOrderId;

  GetProgressByWorkOrderIdEvent(this.workOrderId);
}

class GetWorkOrderProgressDetailEvent extends WorkOrderEvent {
  final int id;

  GetWorkOrderProgressDetailEvent(this.id);
}

class UpdateWorkOrderProgressEvent extends WorkOrderEvent {
  final WorkOrderProgressModel progress;

  UpdateWorkOrderProgressEvent(this.progress);
}

class ResubmitProgressEvent extends WorkOrderEvent {
  final WorkOrderProgressModel progress;

  ResubmitProgressEvent(this.progress);
}

class GetProgressByMemberEvent extends WorkOrderEvent {
  final int workOrderId;

  GetProgressByMemberEvent(this.workOrderId);
}

//progress detail
class GetProgressDetailsEvent extends WorkOrderEvent {
  final int workOrderProgressId;

  GetProgressDetailsEvent(this.workOrderProgressId);
}

class UpdateProgressDetailEvent extends WorkOrderEvent {
  final ProgressDetailEntity progressDetail;

  UpdateProgressDetailEvent(this.progressDetail);
}

//form
class GetFormByWorkOrderTypeIdEvent extends WorkOrderEvent {
  final int workOrderTypeId;

  GetFormByWorkOrderTypeIdEvent(this.workOrderTypeId);
}

//master location
class GetMasterLocationsEvent extends WorkOrderEvent {}

class GetMasterLocationDetailEvent extends WorkOrderEvent {
  final int id;

  GetMasterLocationDetailEvent(this.id);
}
