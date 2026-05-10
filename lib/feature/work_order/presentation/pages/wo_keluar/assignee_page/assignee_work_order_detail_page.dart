import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
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

const double _kActionButtonHeight = 48.0;
const double _kActionButtonRadius = 8.0;

const EdgeInsets _kActionButtonPadding = EdgeInsets.symmetric(
  horizontal: 16.0,
  vertical: 0.0, // tinggi dikontrol via minimumSize
);

const TextStyle _kActionButtonTextStyle = TextStyle(
  fontSize: 14.0,
  fontWeight: FontWeight.w600,
);

final RoundedRectangleBorder _kActionButtonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(_kActionButtonRadius),
);

final Size _kActionButtonMinimumSize = Size.fromHeight(_kActionButtonHeight);

class AssigneeWorkOrderDetailPage extends StatefulWidget {
  final bool isAssignee;
  final int? workOrderId;
  final int? status;
  final bool isOvertime;
  final String? kategoriForm; // 'meter' | 'jaringan' | 'infrastruktur'
  final LatLng? lngLat;
  final String? locationName; // Nama lokasi dari MasterLocation
  final int radiusMeter; // Radius dari MasterLocation untuk pengecekan jarak

  const AssigneeWorkOrderDetailPage({
    super.key,
    this.isAssignee = false,
    this.workOrderId,
    this.status,
    this.isOvertime = false,
    this.kategoriForm,
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

  String _resolveAppBarTitle() {
    if (widget.kategoriForm != null) {
      return WoKategoriForm.label(widget.kategoriForm);
    }
    // Fallback untuk backward compat
    return widget.isOvertime ? "Work Order Lembur" : "Work Order";
  }

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
      appBar: CustomAppBar(title: _resolveAppBarTitle()),
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
                        child: _buildSecondaryOutlinedButton(
                          label: 'Pinjam Material',
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
                        child: _buildSecondaryOutlinedButton(
                          label: 'Kembalikan Material',
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
    Future<void> handleTap() async {
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
    }

    if (mode == 'Mulai') {
      return OutlinedButton(
        onPressed: handleTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.status[2]!, width: 2),
          minimumSize: _kActionButtonMinimumSize,
          shape: _kActionButtonShape,
          padding: _kActionButtonPadding,
          textStyle: _kActionButtonTextStyle,
        ),
        child: Text(mode),
      );
    }

    return ElevatedButton(
      onPressed: handleTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.primary[500],
        minimumSize: _kActionButtonMinimumSize,
        shape: _kActionButtonShape,
        padding: _kActionButtonPadding,
        textStyle: _kActionButtonTextStyle,
      ),
      child: Text(mode),
    );
  }

  Widget _buildSecondaryOutlinedButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: _kActionButtonMinimumSize,
        shape: _kActionButtonShape,
        padding: _kActionButtonPadding,
        textStyle: _kActionButtonTextStyle,
      ),
      child: Text(label),
    );
  }
}
