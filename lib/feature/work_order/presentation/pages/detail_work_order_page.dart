import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:project_mobile_pdam/feature/work_order/domain/entities/master_location_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assignee_page/work_order_report_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/button_interaction.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/progress_card.dart';

class DetailWorkOrderPage extends StatefulWidget {
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
  State<DetailWorkOrderPage> createState() => _DetailWorkOrderPageState();
}

class _DetailWorkOrderPageState extends AppStatePage<DetailWorkOrderPage> {
  Map<String, dynamic> formData = {};
  List<WorkOrderTypeEntity> workOrderTypes = [];
  List<UserEntity> assignees = [];
  // List<UserEntity> assignee = [];
  List<WorkOrderProgressEntity> progresses = [];
  int? status;
  int? splId;
  int? _creatorIdFromDetail;

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
      debugPrint(
        "⚠️ Caller jabatan_id tidak ditemukan; serahkan filter ke backend.",
      );
      return null;
    }

    const int lookahead = 20;
    final ids = List<int>.generate(
      lookahead,
      (index) => callerJabatanId + index + 1,
    );
    debugPrint(
      "🔒 Caller jabatan_id=$callerJabatanId → assignable jabatanIds=$ids",
    );
    return ids;
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      formData[key] = value;
    });
  }

  void _checkDataLoaded() {
    // Hindari `setState` berulang: hanya panggil kalau status berubah.
    final bool ready;
    if (isDetailMode) {
      ready =
          formData.containsKey("assignee") &&
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
          setState(() {
            _detailErrorMessage = state.message;
          });
        }
        if (state is WorkOrderDetailLoaded) {
          status = state.workOrder.statusId;
          splId = state.workOrder.splId;
          _creatorIdFromDetail = state.workOrder.creator;
          setState(() {
            _detailErrorMessage = null;
            formData = {
              "title": state.workOrder.title,
              "jobType": state.workOrder.workOrderType?.name,
              "kategoriForm": state.workOrder.kategoriForm,
              "lokasi":
                  state.workOrder.lokasiText ??
                  state.workOrder.location?.nama ??
                  "",
              "latitude": state.workOrder.latitude,
              "longitude": state.workOrder.longitude,
              "locationId": state.workOrder.locationId,
              "locationName": state.workOrder.location?.nama,
              "radiusMeter": state.workOrder.location?.radiusMeter,
              "startDateTime": state.workOrder.startDateTime,
              "duration": state.workOrder.duration,
              "durationUnit": state.workOrder.durationUnit,
              "endDateTime": state.workOrder.endDateTime,
              "assignee":
                  state.workOrder.assignees ??
                  (state.workOrder.assignee != null
                      ? [state.workOrder.assignee!]
                      : <UserEntity>[]),
            };
            debugPrint("✅ formData Updated: $formData");
            debugPrint(
              "📍 Location ID: ${state.workOrder.locationId}, Radius: ${state.workOrder.location?.radiusMeter}",
            );
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
          final effectivePicId = widget.picId ?? _creatorIdFromDetail;
          debugPrint(
            "routePicId: ${widget.picId}, creatorIdFromDetail: $_creatorIdFromDetail, effectivePicId: $effectivePicId",
          );
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
        widget.isAssignee
            ? const SizedBox()
            : _buildActionButtons(canAssignStaff: canAssignStaff),
        // Text("${widget.status}")
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
        onPressed: _buttonChoosen,
      );
    }

    // For all other cases (already approved, rejected, in progress, etc.)
    // Don't show any buttons (read-only mode)
    return const SizedBox();
  }

  void _buttonChoosen(String action) {
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
    // Cek apakah semua field sudah terisi
    if (formData["title"] == null || formData["title"].trim().isEmpty) {
      AppSnackbar.showError("Judul tidak boleh kosong.");
      return;
    }
    if (formData["jobType"] == null) {
      AppSnackbar.showError("Jenis pekerjaan harus dipilih.");
      return;
    }
    if (formData["lokasi"] == null || formData["lokasi"].trim().isEmpty) {
      AppSnackbar.showError("Lokasi harus diisi.");
      return;
    }
    if (formData["startDateTime"] == null) {
      AppSnackbar.showError("Waktu mulai harus diisi.");
      return;
    }
    if (formData["duration"] == null || formData["duration"] <= 0) {
      AppSnackbar.showError("Durasi harus lebih dari 0.");
      return;
    }
    if (formData["durationUnit"] == null) {
      AppSnackbar.showError("Satuan durasi harus dipilih.");
      return;
    }

    final List<UserEntity> assignees = formData["assignees"] ?? [];
    final List<int> assigneeIds = assignees.map((user) => user.id!).toList();
    debugPrint("🚀 Final Assignees IDs: $assigneeIds"); // Debugging
    if (assigneeIds.isEmpty) {
      AppSnackbar.showError("Minimal 1 petugas harus dipilih.");
      return;
    }

    if (formData["endDateTime"] == null) {
      AppSnackbar.showError("Waktu selesai tidak valid.");
      return;
    }

    // Buat model WorkOrder
    final workOrder = WorkOrderModel(
      title: formData["title"],
      statusId: widget.isOvertime ? 2 : 1, // WO Lembur butuh approval
      startDateTime: formData["startDateTime"],
      duration: formData["duration"],
      durationUnit: formData["durationUnit"],
      endDateTime: formData["endDateTime"],
      assigneeIds: assigneeIds,
      workOrderTypeId: formData["jobType"],
      lokasiText: formData["lokasi"], // Kirim nama lokasi sebagai text
      latitude: formData["latitude"],
      longitude: formData["longitude"],
      locationId:
          formData["locationId"], // ID dari MasterLocation untuk radius check
      location: formData["locationName"] != null
          ? MasterLocationEntity(
              id: formData["locationId"],
              nama: formData["locationName"],
              latitude: formData["latitude"] ?? 0,
              longitude: formData["longitude"] ?? 0,
              radiusMeter: formData["radiusMeter"] ?? 1000,
            )
          : null,
      creator: widget.picId,
      requiresApproval: widget.isOvertime,
    );

    setState(() {
      _isSubmitting = true;
    });

    final bloc = context.read<WorkOrderBloc>();
    bloc.add(CreateWorkOrderEvent(workOrder));
  }

  Future<void> _validateAndAssignStaff() async {
    if (_isSubmitting || widget.workOrderId == null) return;

    final List<UserEntity> selectedAssignees =
        (formData["assignee"] as List<UserEntity>?) ?? <UserEntity>[];
    List<int> staffIds = selectedAssignees
        .map((user) => user.id)
        .whereType<int>()
        .toList();

    if (staffIds.isEmpty) {
      AppSnackbar.showError("Minimal 1 petugas harus dipilih.");
      return;
    }

    final picIdStr = formData["picId"];
    final picId = picIdStr != null ? int.tryParse(picIdStr.toString()) : null;

    if (picId == null || !staffIds.contains(picId)) {
      AppSnackbar.showError(
        "Koordinator (PIC) harus dipilih dari anggota tim yang ditugaskan.",
      );
      return;
    }

    // Pindahkan PIC ke index 0 agar backend tahu itu koordinator
    staffIds.remove(picId);
    staffIds.insert(0, picId);

    // Build form_kategori berdasarkan kategoriForm
    final String kategori = (formData["kategoriForm"] as String?) ?? 'meter';
    final Map<String, dynamic> formKategori;

    switch (kategori) {
      case 'jaringan':
        final jenisPipa = (formData["jenisPipa"] ?? "").toString().trim();
        if (jenisPipa.isEmpty) {
          AppSnackbar.showError("Jenis pipa wajib diisi.");
          return;
        }
        formKategori = {
          'jenis_pipa': jenisPipa,
          if ((formData["diameterPipa"] ?? "").toString().trim().isNotEmpty)
            'diameter_pipa': double.tryParse(
              formData["diameterPipa"].toString(),
            ),
          if ((formData["panjangPipa"] ?? "").toString().trim().isNotEmpty)
            'panjang_pipa': double.tryParse(formData["panjangPipa"].toString()),
          if ((formData["tingkatKerusakan"] ?? "").toString().trim().isNotEmpty)
            'tingkat_kerusakan': formData["tingkatKerusakan"],
        };
        break;
      case 'infrastruktur':
        final namaAset = (formData["namaAset"] ?? "").toString().trim();
        final jenisAset = (formData["jenisAset"] ?? "").toString().trim();
        if (namaAset.isEmpty) {
          AppSnackbar.showError("Nama aset wajib diisi.");
          return;
        }
        if (jenisAset.isEmpty) {
          AppSnackbar.showError("Jenis aset wajib diisi.");
          return;
        }
        formKategori = {
          'nama_aset': namaAset,
          'jenis_aset': jenisAset,
          if ((formData["kapasitas"] ?? "").toString().trim().isNotEmpty)
            'kapasitas': formData["kapasitas"],
          if ((formData["kondisiAwal"] ?? "").toString().trim().isNotEmpty)
            'kondisi_awal': formData["kondisiAwal"],
        };
        break;
      case 'meter':
      default:
        final nomorMeter = (formData["nomorMeter"] ?? "").toString().trim();
        final kondisiMeterAwal = (formData["kondisiMeterAwal"] ?? "")
            .toString()
            .trim();
        if (nomorMeter.isEmpty) {
          AppSnackbar.showError("Nomor meter wajib diisi.");
          return;
        }
        if (kondisiMeterAwal.isEmpty) {
          AppSnackbar.showError("Kondisi meter awal wajib diisi.");
          return;
        }
        formKategori = {
          'nomor_meter': nomorMeter,
          'kondisi_meter_awal': kondisiMeterAwal,
        };
        break;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Ambil lat/lng dari formData (lokasi WO yang di-assign SPV)
    final double? latitude = formData["latitude"] is double
        ? formData["latitude"]
        : double.tryParse(formData["latitude"]?.toString() ?? '');
    final double? longitude = formData["longitude"] is double
        ? formData["longitude"]
        : double.tryParse(formData["longitude"]?.toString() ?? '');

    final result = await _workOrderRemoteDataSource.assignStaff(
      workOrderId: widget.workOrderId!,
      staffIds: staffIds,
      kategoriForm: kategori,
      formKategori: formKategori,
      latitude: latitude,
      longitude: longitude,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result is DataSuccess<void>) {
      AppSnackbar.showSuccess("Assign staff berhasil.");
      context.read<WorkOrderBloc>().add(
        GetWorkOrderDetailEvent(widget.workOrderId!),
      );
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
