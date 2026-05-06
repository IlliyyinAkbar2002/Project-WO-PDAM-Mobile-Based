import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assignee_page/peminjaman_material_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assignee_page/work_order_report_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/detail_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/widgets/progress_card.dart';

final List<Map<String, dynamic>> progressList = [
  {"id": 1, "type": "start", "isFilled": false},
  // {"id": 2, "type": "progress", "isFilled": true, "index": 1},
  // {"id": 3, "type": "progress", "isFilled": false, "index": 2},
  {"id": 4, "type": "finish", "isFilled": false},
];

class AssigneeWorkOrderDetailPage extends StatefulWidget {
  final bool isAssignee;
  final int? workOrderId;
  final int? status;
  final bool isOvertime;
  final LatLng? lngLat;
  final String? locationName; // Nama lokasi dari MasterLocation
  final int radiusMeter; // Radius dari MasterLocation untuk pengecekan jarak

  const AssigneeWorkOrderDetailPage({
    super.key,
    this.isAssignee = false,
    this.workOrderId,
    this.status,
    this.isOvertime = false,
    this.lngLat,
    this.locationName,
    this.radiusMeter = 100, // Default 100 meter jika tidak ada
  });

  @override
  State<AssigneeWorkOrderDetailPage> createState() =>
      _AssigneeWorkOrderDetailPageState();
}

class _AssigneeWorkOrderDetailPageState
    extends AppStatePage<AssigneeWorkOrderDetailPage> {
  List<WorkOrderProgressEntity> progresses = [];

  @override
  void initState() {
    context.read<WorkOrderBloc>().add(
      GetProgressByWorkOrderIdEvent(widget.workOrderId!),
    );
    super.initState();
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: (widget.isOvertime) ? "Work Order Lembur" : "Work Order Normal",
      ),
      body: BlocBuilder<WorkOrderBloc, WorkOrderState>(
        buildWhen: (previous, current) => current is ProgressesLoaded,
        builder: (context, state) {
          if (state is ProgressesLoaded) {
            final progresses = state.progresses;
            final bool hasMulai = progresses.any((item) => item.isMulai);
            final bool hasSelesai = progresses.any((item) => item.isSelesai);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DetailWorkOrderPage(
                  isOvertime: widget.isOvertime,
                  workOrderId: widget.workOrderId,
                  isAssignee: widget.isAssignee,
                  status: widget.status,
                  enableInnerScroll: false,
                ),
                const SizedBox(height: 16),
                Text("Pelaporan Work Order", style: textTheme.displayMedium),
                const SizedBox(height: 8),
                if (!hasMulai)
                  Row(
                    children: [
                      Expanded(child: _buildActionButton('Mulai')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PeminjamanMaterialPage(
                                  workOrderId: widget.workOrderId ?? 0,
                                ),
                              ),
                            );
                          },
                          child: const Text('Pinjam Material'),
                        ),
                      ),
                    ],
                  ),
                ...progresses.map(
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
                            isAssignee: widget.isAssignee,
                            progressId: progressIndex.id,
                            lngLat: widget.lngLat,
                            locationName: widget.locationName,
                            radiusMeter: widget.radiusMeter,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (hasMulai && !hasSelesai) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildActionButton('Selesai')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PeminjamanMaterialPage(
                                  workOrderId: widget.workOrderId ?? 0,
                                ),
                              ),
                            );
                          },
                          child: const Text('Kembalikan Material'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          }

          // Bisa ditambah loading & error handling
          if (state is WorkOrderLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WorkOrderError) {
            return Center(child: Text(state.message));
          }

          return const Center(child: Text("Memuat..."));
        },
      ),
    );
  }

  String _formatEndDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm \'WIB\'');
    return formatter.format(dateTime);
  }

  String? _resolveProgressDateTime(WorkOrderProgressEntity progress) {
    final DateTime? sourceTime =
        progress.submitTime ?? progress.updatedAt ?? progress.createdAt;
    if (sourceTime == null) return null;
    return _formatEndDateTime(sourceTime);
  }

  Widget _buildActionButton(String mode) {
    return ElevatedButton(
      onPressed: () async {
        final bool? shouldRefresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => WorkOrderReportPage(
              mode: mode,
              status: widget.status,
              isAssignee: widget.isAssignee,
              progressId: null,
              workOrderId: widget.workOrderId,
              lngLat: widget.lngLat,
              locationName: widget.locationName,
              radiusMeter: widget.radiusMeter,
            ),
          ),
        );
        if (shouldRefresh == true && mounted && widget.workOrderId != null) {
          context.read<WorkOrderBloc>().add(
            GetProgressByWorkOrderIdEvent(widget.workOrderId!),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: mode == 'Mulai' ? color.status[2] : color.primary[500],
      ),
      child: Text(mode),
    );
  }
}
