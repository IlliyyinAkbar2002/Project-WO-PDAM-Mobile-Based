import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/image_picker.dart';
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

  /// Foto bukti kerusakan. Wajib diisi bila [_rusakController] > 0 — lihat
  /// [_submit]; picker bukan field Form, jadi tidak tercakup `validate()`.
  List<XFile> _fotoKerusakan = [];

  int get _jumlahRusak => int.tryParse(_rusakController.text.trim()) ?? 0;

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
    if (!_formKey.currentState!.validate()) return;

    // Foto jadi syarat begitu staf melaporkan ada barang rusak — SPV perlu
    // bukti visual sebelum menyetujui pengembalian.
    if (_jumlahRusak > 0 && _fotoKerusakan.isEmpty) {
      AppSnackbar.showError(
        'Foto kerusakan wajib diunggah bila ada barang rusak.',
      );
      return;
    }

    context.read<MaterialBloc>().add(
      KembalikanMaterialEvent(
        peminjamanId: widget.peminjaman.id!,
        jumlahKembali: int.parse(_jumlahController.text),
        jumlahRusak: _jumlahRusak,
        kondisiKembali: _kondisiController.text.isNotEmpty
            ? _kondisiController.text
            : null,
        fotoKerusakan: _fotoKerusakan,
      ),
    );
    Navigator.pop(context);
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
      // Ketik manual juga harus memicu rebuild: label & teks bantu foto
      // kerusakan bergantung pada nilai "Jumlah Rusak" (tombol −/+ sudah
      // meng-setState lewat _adjust).
      onChanged: (_) => setState(() {}),
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
    final bool wajibFoto = _jumlahRusak > 0;

    // Padding viewInsets berada DI LUAR area scroll: tinggi area yang bisa
    // di-scroll menyusut mengikuti keyboard, lalu isinya digulung — bukan
    // dipaksa muat (penyebab "BOTTOM OVERFLOWED" saat keyboard muncul).
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
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
                  hintText:
                      'Jumlah barang yang dikembalikan dalam kondisi rusak',
                  min: 0,
                  maxGetter: () => int.tryParse(_jumlahController.text) ?? 0,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final rusak = int.tryParse(value);
                    if (rusak == null || rusak < 0) return 'Tidak valid';
                    final jumlahKembali =
                        int.tryParse(_jumlahController.text) ?? 0;
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
                const SizedBox(height: 16),
                Text(
                  wajibFoto
                      ? 'Foto Kerusakan (Wajib)'
                      : 'Foto Kerusakan (Opsional)',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  wajibFoto
                      ? 'Unggah foto barang yang rusak sebagai bukti untuk supervisor.'
                      : 'Tambahkan foto bila kondisi barang perlu didokumentasikan.',
                  style: textTheme.bodySmall?.copyWith(
                    color: wajibFoto
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF6A7282),
                  ),
                ),
                const SizedBox(height: 8),
                ImagePickerField(
                  initialImages: _fotoKerusakan,
                  onChanged: (images) {
                    setState(() {
                      _fotoKerusakan = (images as List)
                          .whereType<XFile>()
                          .toList();
                    });
                  },
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
        ),
      ),
    );
  }
}
