import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/detail_work_order_keluar/detail_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assignee_page/assignee_work_order_detail_page.dart';

class WorkOrderList extends StatefulWidget {
  final List<int>? status;
  final List<int>? excludeStatus;
  final int? picId;
  final int? userId;
  final int? creatorId;
  final bool isAssignee;

  const WorkOrderList({
    super.key,
    this.status,
    this.excludeStatus,
    this.picId,
    this.userId,
    this.creatorId,
    this.isAssignee = false,
  });

  @override
  State<WorkOrderList> createState() => _WorkOrderListState();
}

class _WorkOrderListState extends AppStatePage<WorkOrderList> {
  final _scrollController = ScrollController();
  late WorkOrderBloc _workOrderBloc;

  @override
  void initState() {
    super.initState();
    _workOrderBloc = context.read<WorkOrderBloc>();
    _scrollController.addListener(_onScroll);
    _fetchWorkOrders();
  }

  void _fetchWorkOrders() {
    _workOrderBloc.add(
      GetWorkOrdersEvent(
        status: widget.status,
        excludeStatus: widget.excludeStatus,
        picId: widget.creatorId ?? widget.picId,
        userId: widget.userId,
        // type: _selectedType,
        // dateRange: _selectedDateRange,
        // startDate: _startDate,
        // endDate: _endDate,
      ),
    );
  }

  void _onScroll() {
    if (_workOrderBloc.currentPage >= _workOrderBloc.totalPages) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      _workOrderBloc.add(
        LoadMoreWorkOrdersEvent(
          _workOrderBloc.currentPage + 1,
          20,
          status: widget.status,
          excludeStatus: widget.excludeStatus,
          picId: widget.picId,
          userId: widget.userId,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context) {
    return BlocBuilder<WorkOrderBloc, WorkOrderState>(
      builder: (context, state) {
        debugPrint("📢 State saat ini: $state");
        if (state is WorkOrderLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is WorkOrderLoaded) {
          debugPrint("✅ Menampilkan ${state.workOrders.length} Work Orders");
          if (state.workOrders.isEmpty) {
            return const Center(child: Text('Belum ada data.'));
          }
          return _buildWorkOrderList(state.workOrders);
        } else if (state is WorkOrderError) {
          return Center(child: Text('Error: ${state.message}')); // ✅ Jika Error
        }
        return const Center(child: Text('Anda offline.'));
      },
    );
  }

  Widget _buildWorkOrderList(List<WorkOrderEntity> workOrders) {
    return ListView.builder(
      shrinkWrap: true, // ✅ Agar mengikuti ukuran kontennya
      controller: _scrollController,
      itemCount:
          workOrders.length +
          (_workOrderBloc.currentPage < _workOrderBloc.totalPages ? 1 : 0),
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        if (index >= workOrders.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final workOrder = workOrders[index];
        return _buildWorkOrderCard(workOrder);
      },
    );
  }

  Widget _buildWorkOrderCard(WorkOrderEntity workOrder) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                workOrder.title,
                style: textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusChip(workOrder),
          ],
        ),
        subtitle: Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                workOrder.workOrderType?.name ?? 'No Type',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (workOrder.createdAt != null)
              Expanded(
                child: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(workOrder.createdAt!),
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final lnglat = workOrder.assignment?.latitude != null
              ? LatLng(
                  workOrder.assignment!.latitude!,
                  workOrder.assignment!.longitude!,
                )
              : null;
          // Ambil radius dan nama lokasi dari location jika ada
          final radiusMeter =
              workOrder.assignment?.location?.radiusMeter ?? 100;
          final locationName = workOrder.assignment?.location?.nama;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => widget.isAssignee
                  ? AssigneeWorkOrderDetailPage(
                      isAssignee: widget.isAssignee,
                      workOrderId: workOrder.id,
                      workOrderTypeId:
                          workOrder.workOrderTypeId ??
                          workOrder.workOrderType?.id,
                      status: workOrder.statusId,
                      kategoriForm: workOrder.kategoriForm,
                      lngLat: lnglat,
                      locationName: locationName,
                      radiusMeter: radiusMeter,
                    )
                  : DetailWorkOrderPage(
                      picId: widget.picId,
                      userId: widget.userId,
                      workOrderId: workOrder.id,
                      status: workOrder.statusId,
                      isOvertime: workOrder.requiresApproval,
                    ),
            ),
          );
          if (mounted) {
            _fetchWorkOrders();
          }
        },
      ),
    );
  }

  Widget _buildStatusChip(WorkOrderEntity workOrder) {
    final kategori =
        workOrder.kategoriForm ?? _inferKategoriFromType(workOrder);
    debugPrint(
      "🎫 List chip — id: ${workOrder.id}, title: '${workOrder.title}', "
      "type: '${workOrder.workOrderType?.name}', "
      "model.kategoriForm: ${workOrder.kategoriForm}, "
      "inferred: ${_inferKategoriFromType(workOrder)}, "
      "final: $kategori",
    );
    final String typeLabel;
    final Color typeColor;
    switch (kategori) {
      case 'meter':
        typeLabel = 'Meter';
        typeColor = color.warning;
        break;
      case 'jaringan':
        typeLabel = 'Jaringan';
        typeColor = color.success;
        break;
      case 'infrastruktur':
        typeLabel = 'Infrastruktur';
        typeColor = const Color(0xFF6366F1); // indigo
        break;
      default:
        typeLabel = workOrder.workOrderType?.name ?? 'WO';
        typeColor = color.success;
    }

    final status = workOrder.status?.status;
    final statusColor =
        color.status[workOrder.status?.id ?? workOrder.statusId] ??
        color.primary[100]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        _buildChip(typeLabel, typeColor),
        if (status != null && status.isNotEmpty)
          _buildChip(status, statusColor),
        if (workOrder.progresPersen != null)
          _buildChip('${workOrder.progresPersen}%', color.primary[500]!),
      ],
    );
  }

  Widget _buildChip(String label, Color backgroundColor) {
    return Container(
      height: 15,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: _chipTextColor(backgroundColor),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _chipTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? color.foreground[900]!
        : Colors.white;
  }

  /// Fallback: derive kategori dari nama workOrderType atau title WO
  String? _inferKategoriFromType(WorkOrderEntity workOrder) {
    final nama = workOrder.workOrderType?.name.toLowerCase() ?? '';
    final title = workOrder.title.toLowerCase();
    final combined = '$nama $title';
    if (combined.contains('pipa') ||
        combined.contains('jaringan') ||
        combined.contains('saluran') ||
        combined.contains('kebocoran')) {
      return 'jaringan';
    }
    if (combined.contains('pompa') ||
        combined.contains('reservoir') ||
        combined.contains('infrastruktur') ||
        combined.contains('aset') ||
        combined.contains('inspeksi') ||
        combined.contains('pemeliharaan')) {
      return 'infrastruktur';
    }
    if (combined.contains('meter') || combined.contains('kalibrasi')) {
      return 'meter';
    }
    return null;
  }
}
