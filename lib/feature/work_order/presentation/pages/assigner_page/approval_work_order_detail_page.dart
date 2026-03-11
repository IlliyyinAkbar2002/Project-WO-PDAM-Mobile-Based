import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/spl_model.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/detail_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/widgets/button_interaction.dart';

class ApprovalWorkOrderDetailPage extends StatefulWidget {
  final int? workOrderId;
  final int? splId;

  const ApprovalWorkOrderDetailPage({super.key, this.workOrderId, this.splId});

  @override
  State<ApprovalWorkOrderDetailPage> createState() =>
      _ApprovalWorkOrderDetailPageState();
}

class _ApprovalWorkOrderDetailPageState
    extends State<ApprovalWorkOrderDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Detail SPL'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DetailWorkOrderPage(
              isOvertime: true,
              workOrderId: widget.workOrderId,
              enableInnerScroll: false,
            ),
            ButtonInteraction(
              status: 1,
              // onPressed: _onSubmit,
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit() {
    final approval = SplModel(id: widget.splId, statusId: 2);

    context.read<WorkOrderBloc>().add(UpdateSplEvent(approval));
  }
}
