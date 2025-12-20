import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mobile_intern_pdam/core/widget/app_state_page.dart';
import 'package:mobile_intern_pdam/core/widget/custom_app_bar.dart';
import 'package:mobile_intern_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/pages/assignee_page/work_order_report_page.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/pages/detail_work_order_page.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/widgets/progress_card.dart';

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
            final progress = progresses[0];
            final progressDetails = progress.progressDetail;

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
                ...progresses.map(
                  (progressIndex) => ProgressCard(
                    type: progressIndex.progressType!,
                    index: progressIndex.order!,
                    description: progressIndex.description,
                    dateTime: progressIndex.updatedAt == progressIndex.createdAt
                        ? null
                        : _formatEndDateTime(progressIndex.updatedAt!),
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
}
