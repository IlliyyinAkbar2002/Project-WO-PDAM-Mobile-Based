import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assigner_page/assigner_work_order_list_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assigner_page/approval_work_order_list_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/widgets/work_order_filter.dart';

class AssignerWorkOrderPage extends StatefulWidget {
  final int?
  picId; // Now optional - backend handles filtering by authenticated user
  const AssignerWorkOrderPage({super.key, this.picId});

  @override
  State<AssignerWorkOrderPage> createState() => _AssignerWorkOrderPageState();
}

class _AssignerWorkOrderPageState extends AppStatePage<AssignerWorkOrderPage> {
  int _selectedFilter = 0; // Index filter utama
  // int _subFilter = 0; // Index filter kedua (jika ada)

  final List<String> _filterLabels = [
    'Pembuatan Work Order',
    'Persetujuan Work Order',
  ];

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Work Order Keluar',
        actionIcon: Icons.notification_add,
        onActionPressed: () {},
      ),
      body: Column(
        children: [
          WorkOrderFilter(
            onFilterSelected: (mainIndex, subIndex) {
              setState(() {
                _selectedFilter = mainIndex;
              });
            },
            filterLabels: _filterLabels,
          ),
          Expanded(child: _getPage()),
        ],
      ),
    );
  }

  Widget _getPage() {
    if (_selectedFilter == 0) {
      return AssignerWorkOrderListPage(picId: widget.picId);
    } else {
      return ApprovalWorkOrderListPage(picId: widget.picId);
    }
  }
}
