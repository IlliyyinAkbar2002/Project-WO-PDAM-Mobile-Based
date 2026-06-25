import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/assigner_page/assigner_work_order_list_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/approval/approval_work_order_list_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/work_order_filter.dart';

class AssignerWorkOrderPage extends StatefulWidget {
  final int?
  picId; // Now optional - backend handles filtering by authenticated user
  const AssignerWorkOrderPage({super.key, this.picId});

  @override
  State<AssignerWorkOrderPage> createState() => _AssignerWorkOrderPageState();
}

class _AssignerWorkOrderPageState extends AppStatePage<AssignerWorkOrderPage> {
  int _selectedFilter = 0; // Index filter utama
  int? get _assignedToPegawaiId => AuthStorage.getUserSync()?['pegawai_id'];

  final List<String> _filterLabels = [
    'List Work Order',
    'History Work Order',
  ];

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Work Order Keluar',
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
      return AssignerWorkOrderListPage(
        picId: widget.picId,
        assignedToPegawaiId: _assignedToPegawaiId,

        excludeStatusNames: const ['Pending'],
        excludeStatus: const [
          WorkOrderStatusId.ditugaskanKeSpv,
          WorkOrderStatusId.selesai,
        ],
      );
    } else {
      return ApprovalWorkOrderListPage(picId: widget.picId);
    }
  }
}
