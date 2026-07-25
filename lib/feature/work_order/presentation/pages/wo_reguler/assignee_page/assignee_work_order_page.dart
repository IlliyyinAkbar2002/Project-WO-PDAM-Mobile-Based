import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/assignee_page/history_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/assignee_page/assignee_work_order_list_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/work_order_filter.dart';

class AssigneeWorkOrderPage extends StatefulWidget {
  final int userId;
  const AssigneeWorkOrderPage({super.key, required this.userId});

  @override
  State<AssigneeWorkOrderPage> createState() => _AssigneeWorkOrderPageState();
}

class _AssigneeWorkOrderPageState extends AppStatePage<AssigneeWorkOrderPage> {
  int _selectedFilter = 0;

  final List<String> _filterLabels = ['Pengerjaan', 'History Laporan Work Order'];

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Work Order',
      ),
      body: Column(
        children: [
          WorkOrderFilter(
            onFilterSelected: (mainIndex, subIndex) {
              setState(() {
                _selectedFilter = mainIndex;
                // _subFilter = subIndex;
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
      return AssigneeWorkOrderListPage(userId: widget.userId);
    } else {
      return HistoryWorkOrderPage(userId: widget.userId);
    }
  }
}
