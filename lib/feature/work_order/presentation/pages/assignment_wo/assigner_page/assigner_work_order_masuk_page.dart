import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/core/widget/filter_list/filter_list.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/approval/approval_work_order_list_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/assigner_page/assigner_work_order_list_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/work_order_filter.dart';

class AssignerWorkOrderMasukPage extends StatefulWidget {
  final int?
  picId; // Now optional - backend handles filtering by authenticated user
  const AssignerWorkOrderMasukPage({super.key, this.picId});

  @override
  State<AssignerWorkOrderMasukPage> createState() =>
      _AssignerWorkOrderMasukPageState();
}

class _AssignerWorkOrderMasukPageState
    extends AppStatePage<AssignerWorkOrderMasukPage> {
  int _selectedFilter = 0;

  int? get _assignedToPegawaiId => AuthStorage.getUserSync()?['pegawai_id'];
  // int? get _departemenId => AuthStorage.getUserSync()?['departemen_id'];

  final List<String> _filterLabels = [
    'Assignment Work Order',
    // 'Assignment History',
  ];

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Work Order Masuk',
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
        filterVariant: WorkOrderFilterVariant.woMasuk,
        // departemenId: _departemenId,
        // WO Masuk = WO yang belum di-assign SPV (status `Pending`). WO nonaktif
        // TETAP ditampilkan (tidak di-onlyActive) supaya SPV tahu ada WO masuk;
        // pengamanannya: tombol "Ajukan" di-hide untuk WO nonaktif (lihat detail).
        includeStatusNames: const ['Pending'],
        // WO yang sudah diajukan lembur (`lembur_spl_id` terisi) pindah jalur ke
        // "Riwayat Pengajuan Lembur" → jangan tampilkan lagi di sini meski
        // status-nya masih 'Pending' sampai di-approve superadmin.
        excludeLembur: true,
        excludeStatus: const [
          WorkOrderStatusId.menungguApprovalManager,
          WorkOrderStatusId.ditugaskanKeStaff,
          WorkOrderStatusId.inProgress,
          WorkOrderStatusId.pengecekan,
          WorkOrderStatusId.selesai,
        ],
      );
    } else {
      return ApprovalWorkOrderListPage(picId: widget.picId);
    }
  }
}
