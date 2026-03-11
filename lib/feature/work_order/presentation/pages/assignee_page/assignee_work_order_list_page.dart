import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_form.dart';
import 'package:project_mobile_pdam/core/widget/filter_list/filter_list.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/work_order_list.dart';

class AssigneeWorkOrderListPage extends StatefulWidget {
  final int userId;
  const AssigneeWorkOrderListPage({super.key, required this.userId});

  @override
  State<AssigneeWorkOrderListPage> createState() =>
      _AssigneeWorkOrderListPageState();
}

class _AssigneeWorkOrderListPageState
    extends AppStatePage<AssigneeWorkOrderListPage> {
  final _searchController = TextEditingController();
  late WorkOrderBloc _workOrderBloc;
  Timer? _debounce;

  // Filter state
  FilterResult? _currentFilter;

  @override
  void initState() {
    super.initState();
    _workOrderBloc = context.read<WorkOrderBloc>();
    _fetchWorkOrders();
  }

  void _fetchWorkOrders() {
    _workOrderBloc.add(
      GetWorkOrdersEvent(
        userId: widget.userId,
        excludeStatus: const [1, 4, 6],
        status: _currentFilter?.statusIds,
        type: _currentFilter?.isOvertime == null
            ? null
            : (_currentFilter!.isOvertime! ? 2 : 1),
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
          _buildWorkOrderList(),
        ],
      ),
    );
  }

  Widget _buildWorkOrderList() {
    return Expanded(
      child: WorkOrderList(
        isAssignee: true,
        excludeStatus: const [1, 4, 6],
        userId: widget.userId,
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
                userId: widget.userId,
                excludeStatus: const [1, 4, 6],
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
