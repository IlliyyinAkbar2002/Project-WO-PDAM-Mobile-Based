import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_form.dart';
import 'package:project_mobile_pdam/core/widget/filter_list/filter_list.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/work_order_list.dart';

class ApprovalWorkOrderListPage extends StatefulWidget {
  final int? picId;
  final int? userId;

  const ApprovalWorkOrderListPage({super.key, this.picId, this.userId});

  @override
  State<ApprovalWorkOrderListPage> createState() =>
      _ApprovalWorkOrderListPageState();
}

class _ApprovalWorkOrderListPageState
    extends AppStatePage<ApprovalWorkOrderListPage> {
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
        status: _currentFilter?.statusIds ?? const [WorkOrderStatusId.selesai],
        picId: widget.picId,
        userId: _currentFilter?.assigneeId ?? widget.userId,
        kategori: _currentFilter?.kategoriForm,
        startDate: _currentFilter?.startDate
            ?.toIso8601String()
            .split('T')
            .first,
        endDate: _currentFilter?.endDate?.toIso8601String().split('T').first,
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
      builder: (context) => const CustomFilterDialog(),
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
              status:
                  _currentFilter?.statusIds ??
                  const [WorkOrderStatusId.selesai],
              picId: widget.picId,
              userId: widget.userId,
              kategoriForm: _currentFilter?.kategoriForm,
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
                userId: _currentFilter?.assigneeId ?? widget.userId,
                status:
                    _currentFilter?.statusIds ??
                    const [WorkOrderStatusId.selesai],
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
