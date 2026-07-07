import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/peminjaman_material_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_bloc.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_event.dart';

class FormKembaliMaterialPage extends StatefulWidget {
  final PeminjamanMaterialEntity peminjaman;

  const FormKembaliMaterialPage({super.key, required this.peminjaman});

  @override
  State<FormKembaliMaterialPage> createState() =>
      _FormKembaliMaterialPageState();
}

class _FormKembaliMaterialPageState
    extends AppStatePage<FormKembaliMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _rusakController = TextEditingController(text: '0');
  final TextEditingController _kondisiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sisaDipinjam =
        (widget.peminjaman.jumlahPinjam ?? 0) -
        (widget.peminjaman.jumlahKembali ?? 0);
    _jumlahController.text = sisaDipinjam.toString();
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _rusakController.dispose();
    _kondisiController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<MaterialBloc>().add(
        KembalikanMaterialEvent(
          peminjamanId: widget.peminjaman.id!,
          jumlahKembali: int.parse(_jumlahController.text),
          jumlahRusak: int.tryParse(_rusakController.text) ?? 0,
          kondisiKembali: _kondisiController.text.isNotEmpty
              ? _kondisiController.text
              : null,
        ),
      );
      Navigator.pop(context);
    }
  }

  /// Mengubah nilai pada [controller] sebesar [delta], lalu menjepit (clamp)
  /// hasilnya ke rentang [min]–[max] agar tidak melampaui batas.
  void _adjust(
    TextEditingController controller,
    int delta,
    int min,
    int max,
  ) {
    final current = int.tryParse(controller.text.trim()) ?? min;
    var next = current + delta;
    if (next < min) next = min;
    if (max >= min && next > max) next = max;
    controller.text = next.toString();
    setState(() {});
  }

  Widget _stepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: const Color(0xFFEFF6FF),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: const Color(0xFF155DFC)),
          ),
        ),
      ),
    );
  }

  /// Input hybrid: tetap bisa diketik manual (untuk angka besar), sekaligus
  /// punya tombol −/+ untuk penyesuaian kecil agar mengurangi salah input.
  Widget _buildStepperField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    required int min,
    required int Function() maxGetter,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w700),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        prefixIcon: _stepperButton(
          icon: Icons.remove,
          onTap: () => _adjust(controller, -1, min, maxGetter()),
        ),
        suffixIcon: _stepperButton(
          icon: Icons.add,
          onTap: () => _adjust(controller, 1, min, maxGetter()),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget buildPage(BuildContext context) {
    final sisaDipinjam =
        (widget.peminjaman.jumlahPinjam ?? 0) -
        (widget.peminjaman.jumlahKembali ?? 0);

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
              'Kembalikan ${widget.peminjaman.material?.namaMaterial ?? ''}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStepperField(
              controller: _jumlahController,
              label: 'Jumlah Kembali',
              min: 1,
              maxGetter: () => sisaDipinjam,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Harus diisi';
                final val = int.tryParse(value);
                if (val == null || val <= 0) return 'Tidak valid';
                if (val > sisaDipinjam) return 'Maksimal $sisaDipinjam';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildStepperField(
              controller: _rusakController,
              label: 'Jumlah Rusak',
              hintText: 'Jumlah barang yang dikembalikan dalam kondisi rusak',
              min: 0,
              maxGetter: () => int.tryParse(_jumlahController.text) ?? 0,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final rusak = int.tryParse(value);
                if (rusak == null || rusak < 0) return 'Tidak valid';
                final jumlahKembali = int.tryParse(_jumlahController.text) ?? 0;
                if (rusak > jumlahKembali) {
                  return 'Maksimal sejumlah yang dikembalikan';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kondisiController,
              decoration: const InputDecoration(
                labelText: 'Kondisi Kembali (Opsional)',
                border: OutlineInputBorder(),
                hintText: 'Catatan kondisi, cth: Baik, lecet ringan',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Simpan Pengembalian'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
