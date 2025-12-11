import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_intern_pdam/config/form_fields_config.dart';
import 'package:mobile_intern_pdam/core/utils/app_snackbar.dart';
import 'package:mobile_intern_pdam/core/utils/auth_storage.dart';
import 'package:mobile_intern_pdam/core/widget/app_state_page.dart';
import 'package:mobile_intern_pdam/core/widget/custom_app_bar.dart';
import 'package:mobile_intern_pdam/core/widget/custom_field_widgets.dart';
import 'package:mobile_intern_pdam/core/widget/dynamic_form_builder.dart';
import 'package:mobile_intern_pdam/feature/work_order/data/models/spl_model.dart';
import 'package:mobile_intern_pdam/feature/work_order/data/models/work_order_model.dart';
import 'package:mobile_intern_pdam/feature/work_order/domain/entities/location_type_entity.dart';
import 'package:mobile_intern_pdam/feature/work_order/domain/entities/user_entity.dart';
import 'package:mobile_intern_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:mobile_intern_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/pages/assignee_page/work_order_report_page.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/widgets/button_interaction.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/widgets/progress_card.dart';

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
  List<LocationTypeEntity> locationTypes = [];
  List<UserEntity> assignees = [];
  // List<UserEntity> assignee = [];
  List<WorkOrderProgressEntity> progresses = [];
  int? status;
  int? splId;
  int? picId;

  bool _isManager = false;

  bool isDataLoaded = false;
  bool get isDetailMode => widget.workOrderId != null;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<WorkOrderBloc>();

    final user = AuthStorage.getUserSync();
    _isManager = user?['role_id'] == 2;

    formData["isOvertime"] = widget.isOvertime;

    if (isDetailMode) {
      bloc.add(GetWorkOrderDetailEvent(widget.workOrderId!));
      bloc.add(GetProgressByWorkOrderIdEvent(widget.workOrderId!));
    } else {
      bloc.add(GetWorkOrderTypesEvent());
      bloc.add(GetLocationTypesEvent());
      bloc.add(GetUsersEvent());
    }
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      formData[key] = value;
    });
  }

  void _checkDataLoaded() {
    if (isDetailMode) {
      // Mode Detail (Pastikan semua field dari formData sudah terisi)
      if (formData.containsKey("assignee") &&
          formData.containsKey("title") &&
          formData.containsKey("startDateTime") &&
          formData.containsKey("duration") &&
          formData.containsKey("durationUnit") &&
          formData.containsKey("endDateTime")) {
        setState(() {
          isDataLoaded = true;
        });
      }
    } else {
      // Mode Pembuatan WO (Hanya butuh dropdown dan daftar user)
      if (workOrderTypes.isNotEmpty &&
          locationTypes.isNotEmpty &&
          assignees.isNotEmpty) {
        setState(() {
          isDataLoaded = true;
        });
      }
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    return BlocListener<WorkOrderBloc, WorkOrderState>(
      listener: (context, state) {
        if (state is WorkOrderTypesLoaded) {
          workOrderTypes = state.workOrderTypes;
        }
        if (state is LocationTypesLoaded) {
          locationTypes = state.locationTypes;
        }
        if (state is UsersLoaded) {
          assignees = state.users;
        }
        if (state is WorkOrderDetailLoaded) {
          status = state.workOrder.statusId;
          splId = state.workOrder.splId;
          picId = state.workOrder.creator;
          setState(() {
            formData = {
              "title": state.workOrder.title,
              "jobType": state.workOrder.workOrderType?.name,
              "locationType": state.workOrder.locationType?.locationType,
              "latitude": state.workOrder.latitude,
              "longitude": state.workOrder.longitude,
              "locationId": state.workOrder.locationId,
              "radiusMeter": state.workOrder.location?.radiusMeter,
              "startDateTime": state.workOrder.startDateTime,
              "duration": state.workOrder.duration,
              "durationUnit": state.workOrder.durationUnit,
              "endDateTime": state.workOrder.endDateTime,
              // "assignees": state.workOrder.assignees,
              "assignee": state.workOrder.assignee != null
                  ? [state.workOrder.assignee!]
                  : [],
            };
            debugPrint("✅ formData Updated: $formData");
            debugPrint(
              "📍 Location ID: ${state.workOrder.locationId}, Radius: ${state.workOrder.location?.radiusMeter}",
            );
            _checkDataLoaded();
          });
        }
        _checkDataLoaded();
      },
      child: BlocBuilder<WorkOrderBloc, WorkOrderState>(
        builder: (context, state) {
          if (state is ProgressesLoaded) {
            progresses = state.progresses;
          }
          print("picId: ${widget.picId}, creatorId: $picId");
          return (widget.enableInnerScroll)
              ? Scaffold(
                  appBar: (widget.workOrderId != null)
                      ? CustomAppBar(
                          title: (widget.isOvertime)
                              ? "Work Order Lembur"
                              : "Work Order Normal",
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
    final formFields = (isDetailMode)
        ? FormFieldsConfig.getDetailWorkOrderFields(
            assigneeOptions: assignees,
            isDetailMode: isDetailMode,
            isAssignee: widget.isAssignee,
            isOvertime: formData["isOvertime"] ?? false,
            status: widget.status,
          )
        : FormFieldsConfig.getWorkOrderFields(
            jobTypeOptions: workOrderTypes,
            locationTypeOptions: locationTypes,
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
                          dateTime:
                              progressIndex.updatedAt == progressIndex.createdAt
                              ? null
                              : _formatEndDateTime(progressIndex.updatedAt!),
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
        widget.isAssignee ? const SizedBox() : _buildActionButtons(),
        // Text("${widget.status}")
      ],
    );
  }

  Widget _buildActionButtons() {
    // If creating a new work order, show submit button
    if (widget.workOrderId == null) {
      return ButtonInteraction(
        status: null,
        onDefaultPressed: _validateAndSubmit,
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
    final approval = SplModel(
      id: splId,
      statusId: action == "Accept" ? 2 : 4,
      verificatorId: widget.userId,
      // verificationDate: DateTime.now(),
    );

    context.read<WorkOrderBloc>().add(UpdateSplEvent(approval));
  }

  void _validateAndSubmit() {
    // Cek apakah semua field sudah terisi
    if (formData["title"] == null || formData["title"].trim().isEmpty) {
      AppSnackbar.showError("Judul tidak boleh kosong.");
      return;
    }
    if (formData["jobType"] == null) {
      AppSnackbar.showError("Jenis pekerjaan harus dipilih.");
      return;
    }
    if (formData["locationType"] == null) {
      AppSnackbar.showError("Jenis lokasi harus dipilih.");
      return;
    }
    if (formData["locationType"] == 1) {
      if (formData["latitude"] == null || formData["longitude"] == null) {
        AppSnackbar.showError("Lokasi harus dipilih.");
        return;
      }
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
      locationTypeId: formData["locationType"],
      latitude: formData["latitude"],
      longitude: formData["longitude"],
      locationId:
          formData["locationId"], // ID dari MasterLocation untuk radius check
      creator: widget.picId,
      requiresApproval: widget.isOvertime,
    );

    // Kirim ke backend
    final bloc = context.read<WorkOrderBloc>();
    bloc.add(CreateWorkOrderEvent(workOrder));

    // Beri notifikasi ke user
    AppSnackbar.showSuccess("Work order berhasil dibuat.");
    _onSubmit();
  }

  Future<void> _onSubmit() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulasi API call

    if (mounted) {
      Navigator.pop(context); // ✅ Hanya dipanggil jika widget masih ada
    }
  }

  String _formatEndDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm \'WIB\'');
    return formatter.format(dateTime);
  }
}
