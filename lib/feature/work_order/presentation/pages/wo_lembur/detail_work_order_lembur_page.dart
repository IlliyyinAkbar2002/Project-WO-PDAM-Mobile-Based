import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/spl_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/lembur_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/lembur_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/lembur_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';

class DetailWorkOrderLemburPage extends StatefulWidget {
  final int workOrderId;
  final bool isAssignee;

  const DetailWorkOrderLemburPage({
    super.key,
    required this.workOrderId,
    this.isAssignee = false,
  });

  @override
  State<DetailWorkOrderLemburPage> createState() =>
      _DetailWorkOrderLemburPageState();
}

class _DetailWorkOrderLemburPageState
    extends AppStatePage<DetailWorkOrderLemburPage> {
  bool _isManager = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    final user = AuthStorage.getUserSync();
    _isManager = user?['role_id'] == 2;
    _userId = user != null
        ? (user['id'] is int
              ? user['id']
              : int.tryParse(user['id']?.toString() ?? ''))
        : null;

    // Load standard detail from WorkOrderBloc
    context.read<WorkOrderBloc>().add(
      GetWorkOrderDetailEvent(widget.workOrderId),
    );

    // Load progresses from LemburBloc
    context.read<LemburBloc>().add(
      GetLemburProgressByWorkOrderIdEvent(widget.workOrderId),
    );
    if (!widget.isAssignee) {
      context.read<LemburBloc>().add(
        GetLemburProgressByMemberEvent(widget.workOrderId),
      );
    }
  }

  void _handleApproval(int splId, bool isAccept) {
    final approval = SplModel(
      id: splId,
      statusId: isAccept ? 2 : 4,
      decision: isAccept ? "accept" : "reject",
      verificatorId: _userId,
    );
    context.read<WorkOrderBloc>().add(UpdateSplEvent(approval));
  }

  void _showProgressReviewDialog(WorkOrderProgressEntity progress) {
    final noteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Review Progres Lembur",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText:
                    "Catatan (Opsional untuk Accept, Wajib untuk Reject)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      if (noteController.text.trim().isEmpty) {
                        AppSnackbar.showWarning(
                          "Catatan wajib diisi untuk menolak/merevisi.",
                        );
                        return;
                      }
                      Navigator.pop(context);
                      // TODO: Dispatch reject event with note using a custom event
                      // context.read<LemburBloc>().add(...)
                    },
                    child: const Text("Revisi (Reject)"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Dispatch accept event
                    },
                    child: const Text("Terima (Accept)"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Detail Lembur"),
      body: MultiBlocListener(
        listeners: [
          BlocListener<WorkOrderBloc, WorkOrderState>(
            listener: (context, state) {
              if (state is SplUpdated) {
                AppSnackbar.showSuccess("Approval SPL berhasil.");
                context.read<WorkOrderBloc>().add(
                  GetWorkOrderDetailEvent(widget.workOrderId),
                );
              }
              if (state is WorkOrderError) {
                AppSnackbar.showError(state.message);
              }
            },
          ),
          BlocListener<LemburBloc, LemburState>(
            listener: (context, state) {
              if (state is LemburError) {
                AppSnackbar.showError(state.message);
              }
            },
          ),
        ],
        child: BlocBuilder<WorkOrderBloc, WorkOrderState>(
          buildWhen: (prev, curr) =>
              curr is WorkOrderDetailLoaded || curr is WorkOrderLoading,
          builder: (context, woState) {
            if (woState is WorkOrderLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (woState is WorkOrderDetailLoaded) {
              final wo = woState.workOrder;
              final isPendingApproval =
                  wo.statusId == 1; // Assuming status 1 is pending SPL

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<WorkOrderBloc>().add(
                    GetWorkOrderDetailEvent(widget.workOrderId),
                  );
                  context.read<LemburBloc>().add(
                    GetLemburProgressByWorkOrderIdEvent(widget.workOrderId),
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade900,
                              Colors.blue.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withAlpha(77), // 0.3 * 255
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(
                                      51,
                                    ), // 0.2 * 255
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    wo.workOrderType?.name ?? "Lembur",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.access_time_filled,
                                  color: Colors.white.withAlpha(204),
                                ), // 0.8 * 255
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              wo.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    wo.lokasiText ??
                                        wo.assignment?.location?.nama ??
                                        "Lokasi tidak diketahui",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        "Waktu Pelaksanaan",
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoTile(
                              "Mulai",
                              wo.startDateTime != null
                                  ? DateFormat(
                                      'dd MMM yyyy, HH:mm',
                                    ).format(wo.startDateTime!)
                                  : "-",
                              Icons.play_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoTile(
                              "Selesai",
                              wo.endDateTime != null
                                  ? DateFormat(
                                      'dd MMM yyyy, HH:mm',
                                    ).format(wo.endDateTime!)
                                  : "-",
                              Icons.check_circle_outline,
                            ),
                          ),
                        ],
                      ),

                      // SPL Approval Section (for Managers)
                      if (_isManager &&
                          isPendingApproval &&
                          wo.splId != null) ...[
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange.shade800,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Menunggu Persetujuan SPL",
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _handleApproval(wo.splId!, false),
                                      child: const Text("Tolak"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      onPressed: () =>
                                          _handleApproval(wo.splId!, true),
                                      child: const Text("Setujui"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Daftar Progres",
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.isAssignee)
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Navigate to progress submission
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("Tambah"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade800,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      BlocBuilder<LemburBloc, LemburState>(
                        builder: (context, lemburState) {
                          if (lemburState is LemburLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (lemburState is LemburProgressesLoaded) {
                            final progresses = lemburState.progresses;
                            if (progresses.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 32,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Belum ada progres",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: progresses.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final prog = progresses[index];
                                final isReviewable =
                                    !widget.isAssignee &&
                                    !_isManager &&
                                    prog.statusId == ProgressStatusId.submitted;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(
                                          10,
                                        ), // 0.04 * 255
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade50,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                    title: Text(
                                      prog.description ?? "Tanpa Deskripsi",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        "Dibuat pada: ${prog.createdAt != null ? DateFormat('HH:mm').format(prog.createdAt!) : ''}",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    trailing: isReviewable
                                        ? ElevatedButton(
                                            onPressed: () =>
                                                _showProgressReviewDialog(prog),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blue.shade50,
                                              foregroundColor:
                                                  Colors.blue.shade700,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text("Review"),
                                          )
                                        : _buildStatusBadge(prog.statusId),
                                  ),
                                );
                              },
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(int? statusId) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade700;
    String label = "Draft";

    if (statusId == ProgressStatusId.verified) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = "Disetujui";
    } else if (statusId == ProgressStatusId.submitted) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
      label = "Menunggu";
    } else if (statusId == ProgressStatusId.revisiRequested) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = "Revisi";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
