import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_form.dart';
import 'package:project_mobile_pdam/core/widget/filter_list/filter_list.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/work_order_list.dart';

class AssignerWorkOrderListPage extends StatefulWidget {
  final int? picId;
  final int? userId;
  final List<int>? excludeStatus;
  final int? assignedToPegawaiId;
  // final int? departemenId;
  final bool onlyActive;
final List<String>? includeStatusNames;
  final List<String>? excludeStatusNames;

  /// Bila true, WO yang sudah diajukan lembur disembunyikan (FE-side).
  /// Dipakai WO Masuk supaya hanya WO reguler yang tampil.
  final bool excludeLembur;

  /// Varian tampilan filter dialog untuk halaman ini (default: filter penuh).
  final WorkOrderFilterVariant filterVariant;

  const AssignerWorkOrderListPage({
    super.key,
    this.picId,
    this.userId,
    this.excludeStatus,
    this.assignedToPegawaiId,
    // this.departemenId,
    this.onlyActive = false,
    this.includeStatusNames,
    this.excludeStatusNames,
    this.excludeLembur = false,
    this.filterVariant = WorkOrderFilterVariant.full,
  });

  @override
  State<AssignerWorkOrderListPage> createState() =>
      _AssignerWorkOrderListPageState();
}

class _AssignerWorkOrderListPageState
    extends AppStatePage<AssignerWorkOrderListPage> {
  final _searchController = TextEditingController();
  late WorkOrderBloc _workOrderBloc;
  Timer? _debounce;

  // Filter state
  FilterResult? _currentFilter;

  @override
  void initState() {
    super.initState();
    _workOrderBloc = context.read<WorkOrderBloc>();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchWorkOrders() {
    _workOrderBloc.add(
      GetWorkOrdersEvent(
        picId: widget.picId,
        excludeStatus: widget.excludeStatus,
        status: _currentFilter?.statusIds,
        userId: _currentFilter?.assigneeId,
        kategori: _currentFilter?.kategoriForm,
        startDate: _currentFilter?.startDate
            ?.toIso8601String()
            .split('T')
            .first,
        endDate: _currentFilter?.endDate?.toIso8601String().split('T').first,
        assignedToPegawaiId: widget.assignedToPegawaiId,
        // departemenId: widget.departemenId,
        onlyActive: widget.onlyActive ? true : null,
        includeStatusNames: widget.includeStatusNames,
        excludeStatusNames: widget.excludeStatusNames,
        excludeLembur: widget.excludeLembur ? true : null,
        onlyLembur: _currentFilter?.onlyLembur,
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final result = await showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => CustomFilterDialog(variant: widget.filterVariant),
    );
    if (result != null) {
      setState(() {
        _currentFilter = result;
      });
      _fetchWorkOrders();
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 8),
          _searchWorkOrder(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Work Order List", style: textTheme.displaySmall),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFilterDialog,
                    ),
                    if (_currentFilter != null && _currentFilter!.hasFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2D499B),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_currentFilter!.filterCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: WorkOrderList(
              picId: widget.picId,
              userId: widget.userId,
              excludeStatus: widget.excludeStatus,
              assignedToPegawaiId: widget.assignedToPegawaiId,
              // departemenId: widget.departemenId,
              onlyActive: widget.onlyActive,
              includeStatusNames: widget.includeStatusNames,
              excludeStatusNames: widget.excludeStatusNames,
              excludeLembur: widget.excludeLembur,
              kategoriForm: _currentFilter?.kategoriForm,
              onlyLembur: _currentFilter?.onlyLembur,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchWorkOrder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomForm(
        labelText: 'Cari Work Order',
        hintText: 'Masukkan kata kunci',
        inputType: InputType.text,
        controller: _searchController,
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            _workOrderBloc.add(
              SearchWorkOrdersEvent(
                value,
                picId: widget.picId,
                excludeStatus: widget.excludeStatus,
                assignedToPegawaiId: widget.assignedToPegawaiId,
                // departemenId: widget.departemenId,
                onlyActive: widget.onlyActive ? true : null,
                includeStatusNames: widget.includeStatusNames,
                excludeStatusNames: widget.excludeStatusNames,
                excludeLembur: widget.excludeLembur ? true : null,
              ),
            );
          });
        },
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            _fetchWorkOrders();
          },
        ),
      ),
    );
  }
}
