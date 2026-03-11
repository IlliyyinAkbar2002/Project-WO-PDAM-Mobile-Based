import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/core/widget/custom_form.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_type_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/widgets/work_order_type_filter.dart';

/// Dynamic Form Page - Form yang dibuat berdasarkan konfigurasi dari web admin
/// Ketika user memilih Jenis Pekerjaan, form akan di-fetch dari API
class DynamicFormPage extends StatefulWidget {
  final int? picId;
  final int? userId;

  const DynamicFormPage({super.key, this.picId, this.userId});

  @override
  State<DynamicFormPage> createState() => _DynamicFormPageState();
}

class _DynamicFormPageState extends AppStatePage<DynamicFormPage> {
  int _subFilterIndex = 0;
  final List<String> _filterLabels = ['WO Normal', 'WO Lembur'];

  List<WorkOrderTypeEntity> workOrderTypes = [];
  int? selectedWorkOrderTypeId;
  bool isLoadingWorkOrderTypes = true;

  Map<String, dynamic> formData = {};

  @override
  void initState() {
    super.initState();
    // Fetch work order types
    context.read<WorkOrderBloc>().add(GetWorkOrderTypesEvent());
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      formData[key] = value;
    });
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Assignment Work Order'),
      body: BlocListener<WorkOrderBloc, WorkOrderState>(
        listener: (context, state) {
          if (state is WorkOrderTypesLoaded) {
            setState(() {
              workOrderTypes = state.workOrderTypes;
              isLoadingWorkOrderTypes = false;
            });
          }
        },
        child: Column(
          children: [
            WorkOrderTypeFilter(
              selectedIndex: _subFilterIndex,
              onFilterSelected: (index) {
                setState(() {
                  _subFilterIndex = index;
                });
              },
              filterLabels: _filterLabels,
            ),
            Expanded(
              child: isLoadingWorkOrderTypes
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Judul Pekerjaan
                          CustomForm(
                            labelText: 'Judul Pekerjaan',
                            hintText: 'Masukkan judul',
                            onChanged: (value) =>
                                _onFieldChanged('title', value),
                          ),
                          const SizedBox(height: 16),

                          // Dropdown Jenis Pekerjaan
                          Text(
                            'Jenis Pekerjaan',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildWorkOrderTypeDropdown(),

                          const SizedBox(height: 24),

                          // Placeholder untuk Dynamic Form Fields
                          if (selectedWorkOrderTypeId != null)
                            _buildDynamicFormPlaceholder(),

                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff2d499b),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Ajukan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkOrderTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedWorkOrderTypeId,
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Pilih jenis pekerjaan',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(8),
          items: workOrderTypes.map((type) {
            return DropdownMenuItem<int>(
              value: type.id,
              child: Text(type.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedWorkOrderTypeId = value;
            });
            // TODO: Fetch dynamic form fields based on selected work order type
            // context.read<WorkOrderBloc>().add(
            //   GetFormFieldsByWorkOrderTypeEvent(value!),
            // );
          },
        ),
      ),
    );
  }

  Widget _buildDynamicFormPlaceholder() {
    final selectedType = workOrderTypes.firstWhere(
      (type) => type.id == selectedWorkOrderTypeId,
      orElse: () => const WorkOrderTypeEntity(name: 'Unknown'),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Form Dinamis',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Jenis Pekerjaan: ${selectedType.name}',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Form fields untuk "${selectedType.name}" akan di-fetch dari API berdasarkan konfigurasi yang dibuat di web admin.',
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODO: Implementasi',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Panggil API /v1/detail-form?jenis_workorder_id=X\n'
                  '2. Parse response ke FormEntity\n'
                  '3. Render menggunakan DynamicFormBuilder',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSubmit() {
    // TODO: Implement form submission
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form submission akan diimplementasikan'),
        backgroundColor: Color(0xff2d499b),
      ),
    );
  }
}
