import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_form.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/Report/laporan_workorder.dart';
import 'package:project_mobile_pdam/service/service_locator.dart';

class ListLaporanWorkorderPage extends StatelessWidget {
  const ListLaporanWorkorderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkOrderBloc>(
      create: (_) => sl<WorkOrderBloc>(),
      child: const _ListLaporanWorkorderPage(),
    );
  }
}

class _ListLaporanWorkorderPage extends StatefulWidget {
  const _ListLaporanWorkorderPage();

  @override
  State<_ListLaporanWorkorderPage> createState() =>
      _ListLaporanWorkorderPageState();
}

class _ListLaporanWorkorderPageState
    extends AppStatePage<_ListLaporanWorkorderPage> {
  final _searchController = TextEditingController();
  late WorkOrderBloc _workOrderBloc;
  Timer? _debounce;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _workOrderBloc = context.read<WorkOrderBloc>();
    _fetchCompletedWorkOrders();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchCompletedWorkOrders() => _applyFilters();

  String? _isoDate(DateTime? date) => date?.toIso8601String().split('T').first;

  /// Staff Senior/Staff hanya boleh melihat laporan WO yang mereka kerjakan
  /// sendiri; SPV tetap melihat seluruh laporan tim/departemennya. `user_id`
  /// adalah query param BE asli (lihat HistoryWorkOrderPage), bukan filter
  /// FE-side seperti assignedToPegawaiId.
  int? get _scopedUserId {
    final isSpv = AuthStorage.getJabatanKodeSync() == 'SPV';
    if (isSpv) return null;
    return AuthStorage.getUserSync()?['id'] as int?;
  }

  /// Memuat laporan sesuai filter aktif: gabungan kata kunci + rentang tanggal.
  void _applyFilters() {
    final query = _searchController.text.trim();
    final startDate = _isoDate(_dateRange?.start);
    final endDate = _isoDate(_dateRange?.end);
    final userId = _scopedUserId;

    if (query.isNotEmpty) {
      _workOrderBloc.add(
        SearchWorkOrdersEvent(
          query,
          status: const [WorkOrderStatusId.selesai],
          startDate: startDate,
          endDate: endDate,
          userId: userId,
          fromHistory: true,
        ),
      );
    } else {
      _workOrderBloc.add(
        GetWorkOrdersEvent(
          status: const [WorkOrderStatusId.selesai],
          startDate: startDate,
          endDate: endDate,
          userId: userId,
          fromHistory: true,
        ),
      );
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _applyFilters();
    }
  }

  void _clearDateRange() {
    setState(() => _dateRange = null);
    _applyFilters();
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History Laporan Work Order')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildSearchBar(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar History Laporan',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _dateRange == null ? 'Filter Tanggal' : 'Ubah Tanggal',
                  ),
                ),
              ],
            ),
          ),
          if (_dateRange != null) _buildDateRangeChip(),
          const SizedBox(height: 8),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomForm(
        labelText: 'Cari History Laporan Work Order',
        hintText: 'Masukkan kata kunci',
        inputType: InputType.text,
        controller: _searchController,
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), _applyFilters);
        },
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            _fetchCompletedWorkOrders();
          },
        ),
      ),
    );
  }

  Widget _buildDateRangeChip() {
    final fmt = DateFormat('dd MMM yyyy', 'id_ID');
    final label =
        '${fmt.format(_dateRange!.start)} - ${fmt.format(_dateRange!.end)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          avatar: const Icon(Icons.event, size: 18),
          label: Text(label),
          onDeleted: _clearDateRange,
          deleteIcon: const Icon(Icons.close, size: 18),
        ),
      ),
    );
  }

  Widget _buildList() {
    return BlocBuilder<WorkOrderBloc, WorkOrderState>(
      builder: (context, state) {
        if (state is WorkOrderLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is WorkOrderError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _fetchCompletedWorkOrders,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (state is WorkOrderLoaded) {
          final workOrders = state.workOrders;

          if (workOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada laporan work order.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _fetchCompletedWorkOrders(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: workOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final wo = workOrders[index];
                return _LaporanCard(
                  workOrder: wo,
                  onTap: () => _navigateToDetail(wo),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _navigateToDetail(WorkOrderEntity wo) {
    // Detail laporan (kode pengaduan, lokasi, petugas, catatan SPV, dll.)
    // dimuat di dalam halaman lewat endpoint workorder/history/{id}.
    final payload = <String, dynamic>{
      'workorder_id': wo.id,
      'is_lembur': wo.isLembur,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LaporanWorkorderPage(payload: payload),
      ),
    );
  }
}

class _LaporanCard extends StatelessWidget {
  final WorkOrderEntity workOrder;
  final VoidCallback onTap;

  const _LaporanCard({required this.workOrder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    String dateStr = '-';
    final completedAt =
        workOrder.tanggalTerbitLaporan ??
        workOrder.updatedAt ??
        workOrder.startDateTime;
    if (completedAt != null) {
      final d = completedAt;
      dateStr =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.assignment_turned_in_outlined,
                  color: Colors.green.shade700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workOrder.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tanggal Terbit · $dateStr',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
