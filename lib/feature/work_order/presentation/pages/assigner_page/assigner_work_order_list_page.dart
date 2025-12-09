import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_intern_pdam/core/widget/app_state_page.dart';
import 'package:mobile_intern_pdam/core/widget/custom_form.dart';
import 'package:mobile_intern_pdam/core/widget/filter_list/filter_list.dart';
import 'package:mobile_intern_pdam/core/widget/speed_dial_fab.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/pages/assigner_page/create_work_order_page.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/pages/assigner_page/dynamic_form_page.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/pages/work_order_list.dart';

class AssignerWorkOrderListPage extends StatefulWidget {
  final int? picId;
  final int? userId;

  const AssignerWorkOrderListPage({super.key, this.picId, this.userId});

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
    _fetchWorkOrders();
  }

  void _fetchWorkOrders() {
    _workOrderBloc.add(
      GetWorkOrdersEvent(
        picId: widget.picId,
        status: _currentFilter?.statusIds,
        userId: _currentFilter?.assigneeId,
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
          Expanded(
            child: WorkOrderList(picId: widget.picId, userId: widget.userId),
          ),
        ],
      ),
      floatingActionButton: SpeedDialFab(
        backgroundColor: const Color(0xff2d499b),
        items: [
          SpeedDialItem(
            label: 'Dynamic Form',
            // Icon: document with lightning bolt (dynamic form dari web)
            iconAsset: 'assets/DynamicForm.png',
            fallbackIcon: Icons.bolt_outlined,
            backgroundColor: const Color(0xFF3B82F6),
            onTap: () async {
              final bloc = context.read<WorkOrderBloc>();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DynamicFormPage(
                    picId: widget.picId,
                    userId: widget.userId,
                  ),
                ),
              );
              if (mounted) {
                bloc.add(
                  GetWorkOrdersEvent(
                    picId: widget.picId,
                    userId: widget.userId,
                  ),
                );
              }
            },
          ),
          SpeedDialItem(
            label: 'Static Form',
            // Icon: checklist with plus sign (form statis)
            iconAsset: 'assets/FormStatis.png',
            fallbackIcon: Icons.playlist_add_check_outlined,
            backgroundColor: const Color(0xFF3B82F6),
            onTap: () async {
              final bloc = context.read<WorkOrderBloc>();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateWorkOrderPage(
                    picId: widget.picId,
                    userId: widget.userId,
                  ),
                ),
              );
              if (mounted) {
                bloc.add(
                  GetWorkOrdersEvent(
                    picId: widget.picId,
                    userId: widget.userId,
                  ),
                );
              }
            },
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
              SearchWorkOrdersEvent(value, picId: widget.picId),
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
