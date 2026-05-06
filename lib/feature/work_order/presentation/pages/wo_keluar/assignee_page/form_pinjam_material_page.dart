import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/material_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/material/material_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/material/material_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/material/material_state.dart';

class FormPinjamMaterialPage extends StatefulWidget {
  final int workOrderId;

  const FormPinjamMaterialPage({super.key, required this.workOrderId});

  @override
  State<FormPinjamMaterialPage> createState() => _FormPinjamMaterialPageState();
}

class _FormPinjamMaterialPageState extends AppStatePage<FormPinjamMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jumlahController = TextEditingController();
  MaterialEntity? _selectedMaterial;

  @override
  void initState() {
    super.initState();
    context.read<MaterialBloc>().add(GetMasterMaterialsEvent());
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedMaterial != null) {
      context.read<MaterialBloc>().add(
            PinjamMaterialEvent(
              workOrderId: widget.workOrderId,
              materialId: _selectedMaterial!.id!,
              jumlahPinjam: int.parse(_jumlahController.text),
            ),
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengajuan Pinjam Material',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            BlocBuilder<MaterialBloc, MaterialState>(
              buildWhen: (previous, current) => current is MasterMaterialsLoaded || current is MaterialLoading || current is MaterialError,
              builder: (context, state) {
                if (state is MaterialLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MasterMaterialsLoaded) {
                  final materials = state.materials;
                  return DropdownButtonFormField<MaterialEntity>(
                    decoration: const InputDecoration(
                      labelText: 'Pilih Material',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedMaterial,
                    items: materials.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text('${m.namaMaterial} (Sisa: ${m.stokTersedia})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedMaterial = val;
                      });
                    },
                    validator: (val) => val == null ? 'Harus dipilih' : null,
                  );
                }

                return const Text('Gagal memuat daftar material');
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jumlahController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Pinjam',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Harus diisi';
                final val = int.tryParse(value);
                if (val == null || val <= 0) return 'Tidak valid';
                if (_selectedMaterial != null && val > _selectedMaterial!.stokTersedia) {
                  return 'Maksimal stok tersedia: ${_selectedMaterial!.stokTersedia}';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Simpan Pengajuan'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
