import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/material_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_bloc.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_event.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_state.dart';
import 'package:project_mobile_pdam/service/service_locator.dart';

class PengajuanItemPage extends StatelessWidget {
  final MaterialEntity material;
  final int workOrderId;

  const PengajuanItemPage({
    super.key,
    required this.material,
    required this.workOrderId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MaterialBloc>(
      create: (_) => sl<MaterialBloc>(),
      child: _PengajuanItemView(material: material, workOrderId: workOrderId),
    );
  }
}

class _PengajuanItemView extends StatefulWidget {
  final MaterialEntity material;
  final int workOrderId;

  const _PengajuanItemView({required this.material, required this.workOrderId});

  @override
  State<_PengajuanItemView> createState() => _PengajuanItemViewState();
}

class _PengajuanItemViewState extends State<_PengajuanItemView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  bool _isSuccess = false;

  @override
  void dispose() {
    _jumlahController.dispose();
    _catatanController.dispose();
    super.dispose();
  }



  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final qty = int.tryParse(_jumlahController.text.trim()) ?? 0;
    final note = _catatanController.text.trim();

    final materialKode = widget.material.kodeMaterial ?? '';
    if (materialKode.isEmpty) {
      AppSnackbar.showError('Kode material tidak valid.');
      return;
    }

    context.read<MaterialBloc>().add(
      PinjamMaterialEvent(
        workOrderId: widget.workOrderId,
        materialKode: materialKode,
        jumlahPinjam: qty,
        catatan: note.isNotEmpty ? note : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: BlocConsumer<MaterialBloc, MaterialState>(
        listener: (context, state) {
          if (state is MaterialActionSuccess) {
            setState(() {
              _isSuccess = true;
            });
          } else if (state is MaterialError) {
            AppSnackbar.showError(state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is MaterialLoading;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _isSuccess
                ? _buildSuccessState(context)
                : _buildFormState(context, isLoading),
          );
        },
      ),
    );
  }

  Widget _buildFormState(BuildContext context, bool isLoading) {
    final m = widget.material;
    final available = m.stokTersedia;

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Peminjaman Material',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101828),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.namaMaterial ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: const Color(0xFF101828),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kode: ${m.kodeMaterial} • Tersedia: $available ${m.satuan ?? ""}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF6A7282)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Jumlah Pinjam'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _jumlahController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Masukkan jumlah yang ingin dipinjam',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF155DFC),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Jumlah pinjam wajib diisi';
                          }
                          final val = int.tryParse(value.trim());
                          if (val == null || val <= 0) {
                            return 'Masukkan jumlah yang valid (minimal 1)';
                          }
                          if (val > available) {
                            return 'Stok tidak mencukupi (maksimal: $available)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Catatan Peminjaman (Opsional)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _catatanController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Keterangan kebutuhan peminjaman...',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                          hintStyle: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFF99A1AF),
                                fontWeight: FontWeight.w500,
                              ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF155DFC),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF155DFC),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Ajukan Peminjaman',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Peminjaman Berhasil!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Peminjaman material berhasil diproses dan stok telah dikurangi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Kembali ke Inventory'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
