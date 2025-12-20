import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_intern_pdam/core/widget/app_state_page.dart';
import 'package:mobile_intern_pdam/feature/work_order/domain/entities/work_order_entity.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/pages/assignee_page/assignee_work_order_detail_page.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/pages/assigner_page/create_work_order_page.dart';

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
            Expanded(
              child: Text(
                workOrder.endDateTime.toString(),
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final lnglat = workOrder.latitude != null
              ? LatLng(workOrder.latitude!, workOrder.longitude!)
              : null;
          // Ambil radius dan nama lokasi dari location jika ada
          final radiusMeter = workOrder.location?.radiusMeter ?? 100;
          final locationName = workOrder.location?.nama;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => widget.isAssignee
                  ? AssigneeWorkOrderDetailPage(
                      isAssignee: widget.isAssignee,
                      workOrderId: workOrder.id,
                      status: workOrder.statusId,
                      lngLat: lnglat,
                      locationName: locationName,
                      radiusMeter: radiusMeter,
                    )
                  : CreateWorkOrderPage(
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
    final type = workOrder.requiresApproval ? "WO Lembur" : "WO Normal";
    final typeColor = workOrder.requiresApproval
        ? color.warning
        : color.success;

    final status = workOrder.status?.status;
    final statusColor = color.status[workOrder.status?.id];

    return Row(
      spacing: 4,
      children: [
        Container(
          height: 15,
          decoration: BoxDecoration(
            color: typeColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 12,
                color: workOrder.requiresApproval
                    ? color.primary[500]
                    : color.foreground[100],
              ),
            ),
          ),
        ),
        Container(
          height: 15,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              status!,
              style: TextStyle(
                fontSize: 12,
                color: workOrder.statusId != 2 && workOrder.statusId != 8
                    ? color.foreground[100]
                    : color.primary[500],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
