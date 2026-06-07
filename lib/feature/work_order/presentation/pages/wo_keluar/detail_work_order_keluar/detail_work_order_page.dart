import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile_pdam/config/form_fields_config.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/core/widget/custom_field_widgets.dart';
import 'package:project_mobile_pdam/core/widget/dynamic_form_builder.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/spl_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/assignment_workorder_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/master_location_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assignee_page/work_order_report_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/button_interaction.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/progress_card.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_by_member_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/detail_work_order_keluar/progress_individu.dart';
import 'package:project_mobile_pdam/service/service_locator.dart';

class DetailWorkOrderPage extends StatelessWidget {
  final int? picId;
  final int? userId;
  final int? workOrderId;
  final int? status;
  final bool isOvertime;
  final bool isAssignee;
  final bool enableInnerScroll;

  const DetailWorkOrderPage({
    super.key,
    this.picId,
    this.userId,
    this.workOrderId,
    this.status,
    required this.isOvertime,
    this.isAssignee = false,
    this.enableInnerScroll = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkOrderBloc>(
      create: (_) => sl<WorkOrderBloc>(),
      child: _DetailWorkOrderPage(
        picId: picId,
        userId: userId,
        workOrderId: workOrderId,
        status: status,
        isOvertime: isOvertime,
        isAssignee: isAssignee,
        enableInnerScroll: enableInnerScroll,
      ),
    );
  }
}

class _DetailWorkOrderPage extends StatefulWidget {
  final int? picId;
  final int? userId;
  final int? workOrderId;
  final int? status;
  final bool isOvertime;
  final bool isAssignee;
  final bool enableInnerScroll;

  const _DetailWorkOrderPage({
    this.picId,
    this.userId,
    this.workOrderId,
    this.status,
    required this.isOvertime,
    this.isAssignee = false,
    this.enableInnerScroll = true,
  });

  @override
  State<_DetailWorkOrderPage> createState() => _DetailWorkOrderPageState();
}

class _DetailWorkOrderPageState extends AppStatePage<_DetailWorkOrderPage> {
  static const String _assigneeKey = "assignee";
  static const String _assigneesKey = "assignees";

  Map<String, dynamic> formData = {};
  List<WorkOrderTypeEntity> workOrderTypes = [];
  List<UserEntity> assignees = [];
  List<WorkOrderProgressEntity> progresses = [];
  ProgressByMemberEntity? progressByMember;
  int? status;
  int? splId;

  bool _isManager = false;
  late final WorkOrderRemoteDataSource _workOrderRemoteDataSource;
  String? _detailErrorMessage;
  bool _assignableUsersRequested = false;

  bool isDataLoaded = false;
  bool _isSubmitting = false;

  bool _hasClosedAfterCreate = false;
  bool get isDetailMode => widget.workOrderId != null;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<WorkOrderBloc>();

    final user = AuthStorage.getUserSync();
    _isManager = user?['role_id'] == 2;
    _workOrderRemoteDataSource = WorkOrderRemoteDataSource();

    formData["isOvertime"] = widget.isOvertime;

    if (isDetailMode) {
      _reloadDetail();
    } else {
      bloc.add(GetWorkOrderTypesEvent());
      _loadAssignableUsers(bloc, user);
    }
  }

  void _loadAssignableUsers(WorkOrderBloc bloc, Map<String, dynamic>? user) {
    if (_assignableUsersRequested) return;
    _assignableUsersRequested = true;
    bloc.add(GetUsersEvent(jabatanIds: _assignableJabatanIds(user)));
  }

  bool _shouldLoadAssignableUsersForDetail() {
    return isDetailMode &&
        !_isManager &&
        !widget.isAssignee &&
        (status ?? widget.status) == WorkOrderStatusId.ditugaskanKeSpv;
  }

  void _reloadDetail() {
    if (!isDetailMode) return;
    final bloc = context.read<WorkOrderBloc>();
    bloc.add(GetWorkOrderDetailEvent(widget.workOrderId!));
    bloc.add(GetProgressByWorkOrderIdEvent(widget.workOrderId!));
    // Fetch progress by member untuk SPV view
    if (!widget.isAssignee) {
      bloc.add(GetProgressByMemberEvent(widget.workOrderId!));
    }
  }

  List<int>? _assignableJabatanIds(Map<String, dynamic>? user) {
    final employee = user?['employee'];
    final dynamic rawPositionId = (employee is Map)
        ? employee['position_id']
        : null;

    final int? callerJabatanId = rawPositionId is int
        ? rawPositionId
        : int.tryParse(rawPositionId?.toString() ?? '');

    if (callerJabatanId == null) {
      return null;
    }

    const int lookahead = 20;
    final ids = List<int>.generate(
      lookahead,
      (index) => callerJabatanId + index + 1,
    );
    return ids;
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      formData[key] = value;
    });
  }

  String _readTrimmedString(String key) {
    return (formData[key] ?? '').toString().trim();
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  List<UserEntity> _toUserEntityList(dynamic value) {
    if (value is List<UserEntity>) return value;
    if (value is List) return value.whereType<UserEntity>().toList();
    return <UserEntity>[];
  }

  String _resolveJobTypeLabel(WorkOrderEntity workOrder) {
    final String? kategori = workOrder.kategoriForm;
    final String? nestedKategori = workOrder.workOrderType?.kategoriForm;
    final String? nestedName = workOrder.workOrderType?.name.trim();

    if (nestedName != null && nestedName.isNotEmpty) {
      if (kategori != null &&
          nestedKategori != null &&
          kategori != nestedKategori) {
        return WoKategoriForm.label(kategori);
      }
      return nestedName;
    }

    return WoKategoriForm.label(kategori);
  }

  Map<String, dynamic> _buildKategoriFormData(WorkOrderEntity workOrder) {
    final Map<String, dynamic>? detail = workOrder.detailKategori;
    if (detail == null) return const {};

    switch (workOrder.kategoriForm) {
      case WoKategoriForm.jaringan:
        return {
          "jenisPipa": detail["jenis_pipa"],
          "diameterPipa": detail["diameter_pipa"]?.toString(),
          "panjangPipa": detail["panjang_pipa"]?.toString(),
          "tingkatKerusakan": detail["tingkat_kerusakan"],
          "tindakan_perbaikan": detail["tindakan_perbaikan"]?.toString(),
          "hasil_inspeksi": detail["hasil_inspeksi"]?.toString(),
        };
      case WoKategoriForm.infrastruktur:
        return {
          "namaAset": detail["nama_aset"],
          "jenisAset": detail["jenis_aset"],
          "kapasitas": detail["kapasitas"]?.toString(),
          "kondisiAwal": detail["kondisi_awal"]?.toString(),
          "kondisi_awal": detail["kondisi_awal"]?.toString(),
          "kondisi_akhir": detail["kondisi_akhir"]?.toString(),
          "jadwal_pemeliharaan": detail["jadwal_pemeliharaan"]?.toString(),
          "tindakan": detail["tindakan"]?.toString(),
        };
      case WoKategoriForm.meter:
        return {
          "nomorMeter": detail["nomor_meter"],
          "kondisiMeterAwal": detail["kondisi_meter_awal"],
          "kondisi_meter_akhir": detail["kondisi_meter_akhir"]?.toString(),
          "hasil_kalibrasi": detail["hasil_kalibrasi"]?.toString(),
        };
      default:
        return const {};
    }
  }

  void _checkDataLoaded() {
    // Hindari `setState` berulang: hanya panggil kalau status berubah.
    final bool ready;
    if (isDetailMode) {
      ready =
          formData.containsKey(_assigneeKey) &&
          formData.containsKey("title") &&
          formData.containsKey("startDateTime") &&
          formData.containsKey("duration") &&
          formData.containsKey("durationUnit") &&
          formData.containsKey("endDateTime");
    } else {
      ready = workOrderTypes.isNotEmpty && assignees.isNotEmpty;
    }

    if (ready && !isDataLoaded && mounted) {
      setState(() {
        isDataLoaded = true;
      });
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    return BlocListener<WorkOrderBloc, WorkOrderState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        if (state is WorkOrderTypesLoaded) {
          workOrderTypes = state.workOrderTypes;
        }
        if (state is UsersLoaded) {
          assignees = state.users;
        }

        if (state is WorkOrderCreated &&
            _isSubmitting &&
            !_hasClosedAfterCreate) {
          // One-shot: pastikan success flow (snackbar + pop) hanya dieksekusi
          // sekali meskipun listener re-fire.
          _hasClosedAfterCreate = true;
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            AppSnackbar.showSuccess("Work order berhasil dibuat.");
            final route = ModalRoute.of(context);
            // Hanya pop kalau route ini masih aktif (isCurrent) dan belum
            // sedang di-pop oleh proses lain. Ini mencegah assertion
            // `entry.currentState == _RouteLifecycle.popping` yang terjadi
            // saat Navigator.pop dipanggil pada route yang sudah dispatch pop.
            if (route != null &&
                route.isActive &&
                route.isCurrent &&
                Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true);
            }
          });
        }
        if (state is WorkOrderError && _isSubmitting) {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            AppSnackbar.showError(state.message);
          });
        }
        if (state is WorkOrderError &&
            isDetailMode &&
            !_isSubmitting &&
            !formData.containsKey("title")) {
          if (mounted) {
            setState(() {
              _detailErrorMessage = state.message;
            });
          }
        }
        if (state is WorkOrderDetailLoaded) {
          status = state.workOrder.statusId;
          splId = state.workOrder.splId;
          final bool canAssignStaff =
              isDetailMode &&
              !_isManager &&
              !widget.isAssignee &&
              state.workOrder.statusId == WorkOrderStatusId.ditugaskanKeSpv;
          debugPrint(
            "📢 DetailWorkOrderPage: state.workOrder.assignment = ${state.workOrder.assignment}",
          );
          debugPrint(
            "📢 DetailWorkOrderPage: state.workOrder.assignment?.assignee = ${state.workOrder.assignment?.assignee}",
          );
          debugPrint(
            "📢 DetailWorkOrderPage: state.workOrder.assignment?.assignee?.employee?.name = ${state.workOrder.assignment?.assignee?.employee?.name}",
          );
          setState(() {
            _detailErrorMessage = null;
            formData = {
              "title": state.workOrder.title,
              "jobType": _resolveJobTypeLabel(state.workOrder),
              "kategoriForm": state.workOrder.kategoriForm,
              "prioritas":
                  (state.workOrder.prioritas != null &&
                      state.workOrder.prioritas!.isNotEmpty)
                  ? (state.workOrder.prioritas![0].toUpperCase() +
                        state.workOrder.prioritas!.substring(1).toLowerCase())
                  : "Sedang",
              "lokasi":
                  state.workOrder.lokasiText ??
                  state.workOrder.assignment?.location?.nama ??
                  "",
              "latitude":
                  state.workOrder.assignment?.latitude ??
                  state.workOrder.assignment?.location?.latitude,
              "longitude":
                  state.workOrder.assignment?.longitude ??
                  state.workOrder.assignment?.location?.longitude,
              "locationId": state.workOrder.assignment?.locationId,
              "locationName": state.workOrder.assignment?.location?.nama,
              "radiusMeter": state.workOrder.assignment?.location?.radiusMeter,
              "startDateTime": canAssignStaff ? null : state.workOrder.startDateTime,
              "duration": state.workOrder.duration,
              "durationUnit": state.workOrder.durationUnit,
              "endDateTime": canAssignStaff ? null : state.workOrder.endDateTime,
              "deskripsiPekerjaan":
                  state.workOrder.assignment?.description ?? "",
              "picId": state.workOrder.assignment?.assigneeId,
              "picName":
                  state.workOrder.assignment?.assignee?.employee?.name ??
                  state.workOrder.assignment?.assignee?.email ??
                  "",
              ..._buildKategoriFormData(state.workOrder),
              _assigneeKey:
                  state.workOrder.assignment?.assignees ??
                  (state.workOrder.assignment?.assignee != null
                      ? [state.workOrder.assignment!.assignee!]
                      : <UserEntity>[]),
            };
            _checkDataLoaded();
          });
          if (_shouldLoadAssignableUsersForDetail()) {
            _loadAssignableUsers(
              context.read<WorkOrderBloc>(),
              AuthStorage.getUserSync(),
            );
          }
        }
        _checkDataLoaded();
      },
      child: BlocBuilder<WorkOrderBloc, WorkOrderState>(
        builder: (context, state) {
          if (state is ProgressesLoaded) {
            progresses = state.progresses;
          }
          if (state is ProgressByMemberLoaded) {
            progressByMember = state.progressByMember;
          }
          if (isDetailMode && !isDataLoaded) {
            if (_detailErrorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _detailErrorMessage!,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _reloadDetail,
                        child: const Text('Muat Ulang Detail'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          return (widget.enableInnerScroll)
              ? Scaffold(
                  appBar: (widget.workOrderId != null)
                      ? CustomAppBar(
                          title: WoKategoriForm.label(
                            formData["kategoriForm"] as String?,
                          ),
                        )
                      : null,
                  body: (state is WorkOrderLoading && isDetailMode)
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildFormContent(progresses),
                        ),
                )
              : _buildFormContent(progresses);
        },
      ),
    );
  }

  Widget _buildFormContent(List<WorkOrderProgressEntity>? progresses) {
    final bool canAssignStaff =
        isDetailMode &&
        !_isManager &&
        !widget.isAssignee &&
        (status ?? widget.status) == WorkOrderStatusId.ditugaskanKeSpv;

    final formFields = (isDetailMode)
        ? FormFieldsConfig.getDetailWorkOrderFields(
            assigneeOptions: assignees,
            isDetailMode: isDetailMode,
            isAssignee: widget.isAssignee,
            isOvertime: formData["isOvertime"] ?? false,
            isAssignMode: canAssignStaff,
            status: widget.status,
            kategoriForm: formData["kategoriForm"] as String?,
          )
        : FormFieldsConfig.getWorkOrderFields(
            jobTypeOptions: workOrderTypes,
            assigneeOptions: assignees,
            isDetailMode: isDetailMode,
            isOvertime: formData["isOvertime"] ?? false,
          );
    return Column(
      children: [
        DynamicFormBuilder(
          key: ValueKey(formData["isOvertime"]),
          fields: formFields,
          formData: formData,
          onFieldChanged: _onFieldChanged,
          customWidgets: CustomFieldWidgets.fields,
        ),
        !widget.isAssignee &&
                progresses != null &&
                progresses.isNotEmpty &&
                progresses.first.description != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pelaporan Work Order", style: textTheme.displayMedium),
                  const SizedBox(height: 10),
                  ...progresses
                      .where(
                        (progressIndex) => progressIndex.description != null,
                      )
                      .map(
                        (progressIndex) => ProgressCard(
                          type: progressIndex.progressType!,
                          index: progressIndex.order!,
                          description: progressIndex.description,
                          dateTime: _resolveProgressDateTime(progressIndex),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkOrderReportPage(
                                  mode: progressIndex.progressType!,
                                  status: widget.status,
                                  progressId: progressIndex.id,
                                  workOrderId: widget.workOrderId,
                                  kategoriForm:
                                      formData["kategoriForm"] as String?,
                                  initialKategoriData: formData,
                                  lngLat:
                                      (formData["latitude"] != null &&
                                          formData["longitude"] != null)
                                      ? LatLng(
                                          (formData["latitude"] as num)
                                              .toDouble(),
                                          (formData["longitude"] as num)
                                              .toDouble(),
                                        )
                                      : null,
                                  locationName:
                                      formData["locationName"] as String?,
                                  radiusMeter:
                                      (formData["radiusMeter"] as int?) ?? 100,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  const SizedBox(height: 16),
                ],
              )
            : const SizedBox(),
        // Progress Individual Anggota (untuk SPV)
        !widget.isAssignee && progressByMember != null
            ? IndividualProgressSection(
                progressByMember: progressByMember!,
                status: widget.status,
                kategoriForm: formData["kategoriForm"] as String?,
                lngLat:
                    (formData["latitude"] != null &&
                        formData["longitude"] != null)
                    ? LatLng(
                        (formData["latitude"] as num).toDouble(),
                        (formData["longitude"] as num).toDouble(),
                      )
                    : null,
                locationName: formData["locationName"] as String?,
                radiusMeter: (formData["radiusMeter"] as int?) ?? 100,
              )
            : const SizedBox(),
        widget.isAssignee
            ? const SizedBox()
            : _buildActionButtons(canAssignStaff: canAssignStaff),
      ],
    );
  }

  Widget _buildActionButtons({required bool canAssignStaff}) {
    // If creating a new work order, show submit button
    if (widget.workOrderId == null) {
      return ButtonInteraction(
        status: null,
        onDefaultPressed: _isSubmitting ? null : _validateAndSubmit,
      );
    }

    if (canAssignStaff) {
      return ButtonInteraction(
        status: null,
        onDefaultPressed: _isSubmitting ? null : _validateAndAssignStaff,
      );
    }

    // Only managers can approve/reject existing work orders
    if (!_isManager) {
      return const SizedBox();
    }

    final int? currentStatus = status ?? widget.status;
    final bool isPending = currentStatus == 1;
    final bool requiresApproval =
        widget.isOvertime || formData["isOvertime"] == true;

    if (isPending && requiresApproval) {
      return ButtonInteraction(
        status: currentStatus,
        onPressed: _handleApprovalAction,
      );
    }

    // For all other cases (already approved, rejected, in progress, etc.)
    // Don't show any buttons (read-only mode)
    return const SizedBox();
  }

  void _handleApprovalAction(String action) {
    final isAccept = action == "Accept";
    final approval = SplModel(
      id: splId,
      statusId: isAccept ? 2 : 4,
      decision: isAccept ? "accept" : "reject",
      verificatorId: widget.userId,
      // verificationDate: DateTime.now(),
    );

    context.read<WorkOrderBloc>().add(UpdateSplEvent(approval));
  }

  void _validateAndSubmit() {
    // Cegah double-submit: kalau request sebelumnya belum selesai, abaikan.
    if (_isSubmitting) {
      debugPrint("⏳ Submit sedang berjalan, abaikan klik Ajukan tambahan.");
      return;
    }

    final String title = _readTrimmedString("title");
    final int? workOrderTypeId = _toInt(formData["jobType"]);
    final String lokasiText = _readTrimmedString("lokasi");
    final DateTime? startDateTime = _toDateTime(formData["startDateTime"]);
    final int? duration = _toInt(formData["duration"]);
    final String durationUnit = _readTrimmedString("durationUnit");
    final DateTime? endDateTime = _toDateTime(formData["endDateTime"]);
    final List<int> assigneeIds = _toUserEntityList(
      formData[_assigneesKey],
    ).map((user) => user.id).whereType<int>().toList();
    final int? locationId = _toInt(formData["locationId"]);
    final double? latitude = _toDouble(formData["latitude"]);
    final double? longitude = _toDouble(formData["longitude"]);
    final String locationName = _readTrimmedString("locationName");

    // Cek apakah semua field sudah terisi
    if (title.isEmpty) {
      AppSnackbar.showError("Judul tidak boleh kosong.");
      return;
    }
    if (workOrderTypeId == null) {
      AppSnackbar.showError("Jenis pekerjaan harus dipilih.");
      return;
    }
    if (lokasiText.isEmpty) {
      AppSnackbar.showError("Lokasi harus diisi.");
      return;
    }
    if (startDateTime == null) {
      AppSnackbar.showError("Waktu mulai harus diisi.");
      return;
    }
    if (endDateTime == null) {
      AppSnackbar.showError("Waktu selesai harus diisi.");
      return;
    }
    if (endDateTime.isBefore(startDateTime)) {
      AppSnackbar.showError("Waktu selesai tidak boleh mendahului waktu mulai.");
      return;
    }
    if (assigneeIds.isEmpty) {
      AppSnackbar.showError("Minimal 1 petugas harus dipilih.");
      return;
    }

    // Buat model WorkOrder
    final workOrder = WorkOrderModel(
      title: title,
      startDateTime: startDateTime,
      duration: duration,
      durationUnit: durationUnit,
      endDateTime: endDateTime,
      workOrderTypeId: workOrderTypeId,
      lokasiText: lokasiText,
      creator: widget.picId,
      requiresApproval: widget.isOvertime,
      assignment: AssignmentWorkorderEntity(
        assigneeIds: assigneeIds,
        latitude: latitude,
        longitude: longitude,
        locationId: locationId,
        location: locationName.isNotEmpty
            ? MasterLocationEntity(
                id: locationId,
                nama: locationName,
                latitude: latitude ?? 0,
                longitude: longitude ?? 0,
                radiusMeter: _toInt(formData["radiusMeter"]) ?? 1000,
              )
            : null,
      ),
    );

    setState(() {
      _isSubmitting = true;
    });

    final bloc = context.read<WorkOrderBloc>();
    bloc.add(CreateWorkOrderEvent(workOrder));
  }

  Future<void> _validateAndAssignStaff() async {
    if (_isSubmitting || widget.workOrderId == null) return;

    final List<UserEntity> selectedAssignees = _toUserEntityList(
      formData[_assigneeKey],
    );
    List<int> staffIds = selectedAssignees
        .map((user) => user.id)
        .whereType<int>()
        .toList();

    if (staffIds.isEmpty) {
      AppSnackbar.showError("Minimal 1 petugas harus dipilih.");
      return;
    }

    final int? picId = _toInt(formData["picId"]);

    if (picId == null || !staffIds.contains(picId)) {
      AppSnackbar.showError(
        "Koordinator (PIC) harus dipilih dari anggota tim yang ditugaskan.",
      );
      return;
    }

    // Pindahkan PIC ke index 0 agar backend tahu itu koordinator
    staffIds.remove(picId);
    staffIds.insert(0, picId);

    // Build form_kategori berdasarkan kategoriForm.
    // Field kategori "awal" kini diisi oleh staff lapangan saat menekan
    // "Mulai" (lihat WorkOrderReportPage). SPV cukup menentukan petugas, PIC,
    // dan deskripsi, sehingga form_kategori dikirim kosong.
    final String kategoriForm = _readTrimmedString("kategoriForm");
    final String kategori = kategoriForm.isEmpty
        ? WoKategoriForm.meter
        : kategoriForm;
    final Map<String, dynamic> formKategori = const {};

    final double? assignLatitude = _toDouble(formData["latitude"]);
    final double? assignLongitude = _toDouble(formData["longitude"]);
    final int? locationId = _toInt(formData["locationId"]);
    final String locationName = _readTrimmedString("locationName");

    // Location is considered unset if locationId is null, locationName is empty,
    // coordinates are null/zero, or coordinates match the default fallback (-7.2704960, 112.5672211).
    final bool isDefaultLocation =
        assignLatitude != null &&
        assignLongitude != null &&
        (assignLatitude - -7.2704960).abs() < 0.000001 &&
        (assignLongitude - 112.5672211).abs() < 0.000001;

    if (locationId == null ||
        locationName.isEmpty ||
        assignLatitude == null ||
        assignLongitude == null ||
        (assignLatitude == 0 && assignLongitude == 0) ||
        isDefaultLocation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lokasi Belum Ditentukan'),
          content: const Text(
            'Lokasi penugasan belum diatur. Apakah Anda yakin ingin melanjutkan penugasan ke staff tanpa lokasi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Ya, Lanjutkan'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }
    }

    final String lokasiText = _readTrimmedString("lokasi");
    final DateTime? tanggalMulai = _toDateTime(formData["startDateTime"]);
    final DateTime? tanggalSelesai = _toDateTime(formData["endDateTime"]);
    final DateTime? estimasiSelesai = _toDateTime(formData["endDateTime"]);
    final String deskripsi = _readTrimmedString("deskripsiPekerjaan");

    if (tanggalMulai == null) {
      AppSnackbar.showError("Waktu mulai harus diisi.");
      return;
    }
    if (estimasiSelesai == null) {
      AppSnackbar.showError("Estimasi selesai harus diisi.");
      return;
    }
    if (estimasiSelesai.isBefore(tanggalMulai)) {
      AppSnackbar.showError("Estimasi selesai tidak boleh mendahului waktu mulai.");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await _workOrderRemoteDataSource.assignStaff(
      workOrderId: widget.workOrderId!,
      staffIds: staffIds,
      kategoriForm: kategori,
      formKategori: formKategori,
      deskripsi: deskripsi.isEmpty ? null : deskripsi,
      lokasi: lokasiText.isEmpty ? null : lokasiText,
      latitude: assignLatitude,
      longitude: assignLongitude,
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      estimasiSelesai: estimasiSelesai,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result is DataSuccess<WorkOrderModel?>) {
      AppSnackbar.showSuccess("Assign staff berhasil.");
      final WorkOrderModel? updatedWorkOrder = result.data;
      if (updatedWorkOrder != null) {
        context.read<WorkOrderBloc>().add(
          SetWorkOrderDetailEvent(updatedWorkOrder),
        );
      } else {
        context.read<WorkOrderBloc>().add(
          GetWorkOrderDetailEvent(widget.workOrderId!),
        );
      }
      context.read<WorkOrderBloc>().add(
        GetProgressByWorkOrderIdEvent(widget.workOrderId!),
      );
      return;
    }

    final message =
        (result as DataFailed).error?.toString() ?? "Gagal assign staff.";
    AppSnackbar.showError(message);
  }

  String? _resolveProgressDateTime(WorkOrderProgressEntity progress) {
    final DateTime? sourceTime =
        progress.submitTime ?? progress.updatedAt ?? progress.createdAt;
    if (sourceTime == null) return null;
    return _formatEndDateTime(sourceTime);
  }

  String _formatEndDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm \'WIB\'');
    return formatter.format(dateTime);
  }
}
