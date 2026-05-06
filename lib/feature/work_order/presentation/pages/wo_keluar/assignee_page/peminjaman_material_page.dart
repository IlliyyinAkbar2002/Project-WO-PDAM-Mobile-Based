import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/peminjaman_material_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/material/material_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/material/material_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/material/material_state.dart';
import 'form_pinjam_material_page.dart';
import 'form_kembali_material_page.dart';

class PeminjamanMaterialPage extends StatefulWidget {
  final int workOrderId;
  const PeminjamanMaterialPage({super.key, required this.workOrderId});

  @override
  State<PeminjamanMaterialPage> createState() => _PeminjamanMaterialPageState();
}

class _PeminjamanMaterialPageState extends AppStatePage<PeminjamanMaterialPage> {
  late MaterialBloc _materialBloc;

  @override
  void initState() {
    super.initState();
    _materialBloc = context.read<MaterialBloc>();
    _fetchData();
  }

  void _fetchData() {
    _materialBloc.add(GetPeminjamanByWoEvent(widget.workOrderId));
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Manajemen Material"),
      body: BlocConsumer<MaterialBloc, MaterialState>(
        listener: (context, state) {
          if (state is MaterialActionSuccess) {
            AppSnackbar.showSuccess(state.message);
            _fetchData();
          } else if (state is MaterialError) {
            AppSnackbar.showError(state.message);
          }
        },
        buildWhen: (previous, current) =>
            current is MaterialLoading || current is PeminjamanLoaded || current is MaterialError,
        builder: (context, state) {
          if (state is MaterialLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PeminjamanLoaded) {
            if (state.peminjamanList.isEmpty) {
              return const Center(child: Text('Belum ada material yang dipinjam untuk WO ini.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.peminjamanList.length,
              itemBuilder: (context, index) {
                final item = state.peminjamanList[index];
                return _buildPeminjamanCard(item);
              },
            );
          }

          if (state is MaterialError) {
            return Center(child: Text(state.message));
          }

          return const Center(child: Text('Memuat...'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showPinjamForm(context);
        },
        label: const Text('Pinjam Material'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPeminjamanCard(PeminjamanMaterialEntity item) {
    final sisaDipinjam = (item.jumlahPinjam ?? 0) - (item.jumlahKembali ?? 0);
    final canReturn = sisaDipinjam > 0 && item.status != 'DIKEMBALIKAN';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.material?.namaMaterial ?? 'Material #${item.materialId}',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.status ?? 'UNKNOWN',
                    style: TextStyle(color: color.foreground[100], fontSize: 12),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text('Jumlah Pinjam: ${item.jumlahPinjam} ${item.material?.satuan ?? ""}'),
            if ((item.jumlahKembali ?? 0) > 0)
              Text('Jumlah Kembali: ${item.jumlahKembali} ${item.material?.satuan ?? ""}'),
            if (item.waktuPinjam != null) Text('Waktu Pinjam: ${item.waktuPinjam}'),
            if (canReturn) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showKembaliForm(context, item);
                  },
                  child: const Text('Kembalikan Material'),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'DIPINJAM') return color.warning;
    if (status == 'DIKEMBALIKAN') return color.success;
    if (status == 'DITOLAK') return color.danger;
    return color.primary[500]!;
  }

  void _showPinjamForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FormPinjamMaterialPage(workOrderId: widget.workOrderId),
    ).then((_) {
      // Re-fetch in case there are changes that didn't trigger listener
      _fetchData();
    });
  }

  void _showKembaliForm(BuildContext context, PeminjamanMaterialEntity item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FormKembaliMaterialPage(peminjaman: item),
    ).then((_) {
      _fetchData();
    });
  }
}
