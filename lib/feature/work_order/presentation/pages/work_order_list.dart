import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/utils/work_order_status_helper.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/detail_work_order/detail_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/assignee_page/assignee_work_order_detail_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_lembur/detail_work_order_page_lembur.dart';

class WorkOrderList extends StatefulWidget {
  final List<int>? status;
  final List<int>? excludeStatus;
  final int? picId;
  final int? userId;
  final int? creatorId;
  final bool isAssignee;
  final int? assignedToPegawaiId;
  // final int? departemenId;
  final bool onlyActive;
  final List<String>? includeStatusNames;
  final List<String>? excludeStatusNames;

  const WorkOrderList({
    super.key,
    this.status,
    this.excludeStatus,
    this.picId,
    this.userId,
    this.creatorId,
    this.isAssignee = false,
    this.assignedToPegawaiId,
    // this.departemenId,
    this.onlyActive = false,
    this.includeStatusNames,
    this.excludeStatusNames,
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
        assignedToPegawaiId: widget.assignedToPegawaiId,
        // departemenId: widget.departemenId,
        onlyActive: widget.onlyActive ? true : null,
        includeStatusNames: widget.includeStatusNames,
        excludeStatusNames: widget.excludeStatusNames,
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
          assignedToPegawaiId: widget.assignedToPegawaiId,
          //  departemenId: widget.departemenId,
          onlyActive: widget.onlyActive ? true : null,
          includeStatusNames: widget.includeStatusNames,
          excludeStatusNames: widget.excludeStatusNames,
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
          return _WorkOrderListErrorView(
            message: state.message,
            onRetry: _fetchWorkOrders,
          );
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workOrder.title,
              style: textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
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
              builder: (context) {
                if (workOrder.isLembur) {
                  return DetailWorkOrderPageLembur(
                    workOrderId: workOrder.id,
                    workOrderTypeId:
                        workOrder.workOrderTypeId ??
                        workOrder.workOrderType?.id,
                    status: workOrder.statusId,
                    kategoriForm: workOrder.kategoriForm,
                    lngLat: lnglat,
                    locationName: locationName,
                    radiusMeter: radiusMeter,
                    isAssignee: widget.isAssignee,
                  );
                }
                return widget.isAssignee
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
                      );
              },
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

    final status = WorkOrderStatusHelper.getLabel(workOrder);
    final statusColor = WorkOrderStatusHelper.getColor(workOrder, color);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (workOrder.isLembur) _buildChip('Lembur', Colors.orange.shade700),
        _buildChip(typeLabel, typeColor),
        // if (workOrder.departemenNama != null &&
        //     workOrder.departemenNama!.isNotEmpty)
        //   _buildChip(workOrder.departemenNama!, const Color(0xFF0EA5E9)),
        if (status.isNotEmpty && status != '-')
          _buildChip(status, statusColor),
        if (workOrder.isActive == false)
          _buildChip('Nonaktif', const Color(0xFF94A3B8)),
        if (_progresPersen(workOrder) != null)
          _buildChip('${_progresPersen(workOrder)}%', color.primary[500]!),
      ],
    );
  }

  /// Persentase progress WO. Pakai `progresPersen` dari backend kalau ada,
  /// kalau tidak hitung dari `tahapanTertinggi` (dari 4 tahapan pekerjaan).
  int? _progresPersen(WorkOrderEntity workOrder) {
    if (workOrder.progresPersen != null) return workOrder.progresPersen;
    final tahapan = workOrder.tahapanTertinggi;
    if (tahapan == null || tahapan <= 0) return null;
    return ((tahapan.clamp(0, 4) / 4) * 100).round();
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

class _WorkOrderListErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _WorkOrderListErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
