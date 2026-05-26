import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_form.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/Report/laporan_workorder.dart';

class ListLaporanWorkorderPage extends StatefulWidget {
  const ListLaporanWorkorderPage({super.key});

  @override
  State<ListLaporanWorkorderPage> createState() =>
      _ListLaporanWorkorderPageState();
}

class _ListLaporanWorkorderPageState
    extends AppStatePage<ListLaporanWorkorderPage> {
  final _searchController = TextEditingController();
  late WorkOrderBloc _workOrderBloc;
  Timer? _debounce;

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

  void _fetchCompletedWorkOrders() {
    _workOrderBloc.add(
      GetWorkOrdersEvent(status: const [WorkOrderStatusId.selesai]),
    );
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Work Order')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildSearchBar(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Daftar Laporan',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
        labelText: 'Cari Laporan',
        hintText: 'Masukkan kata kunci',
        inputType: InputType.text,
        controller: _searchController,
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            _workOrderBloc.add(
              SearchWorkOrdersEvent(
                value,
                status: const [WorkOrderStatusId.selesai],
              ),
            );
          });
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
    // Get assignee details from assignment if available
    final assigneeName = wo.assignment?.assignee?.employee?.name ?? '-';
    final assigneeNip = wo.assignment?.assignee?.employee?.nip ?? '-';
    final assigneeUnit = wo.assignment?.assignee?.employee?.departemen ?? '-';

    final payload = <String, dynamic>{
      'workorder_id': wo.id,
      'nomor_laporan': 'LP-${wo.id}',
      'hasil_akhir_snapshot': wo.title,
      'petugas_snapshot': {
        'nama': assigneeName,
        'nip': assigneeNip,
        'unit': assigneeUnit,
      },
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
    if (workOrder.startDateTime != null) {
      final d = workOrder.startDateTime!;
      dateStr =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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
                      'Selesai · $dateStr',
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
