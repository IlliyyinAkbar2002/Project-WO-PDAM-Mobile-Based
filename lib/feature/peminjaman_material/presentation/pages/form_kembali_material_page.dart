import 'package:flutter/material.dart';
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
    _kondisiController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<MaterialBloc>().add(
        KembalikanMaterialEvent(
          peminjamanId: widget.peminjaman.id!,
          jumlahKembali: int.parse(_jumlahController.text),
          kondisiKembali: _kondisiController.text.isNotEmpty
              ? _kondisiController.text
              : null,
        ),
      );
      Navigator.pop(context);
    }
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
            TextFormField(
              controller: _jumlahController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Kembali',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Harus diisi';
                final val = int.tryParse(value);
                if (val == null || val <= 0) return 'Tidak valid';
                if (val > sisaDipinjam) return 'Maksimal $sisaDipinjam';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kondisiController,
              decoration: const InputDecoration(
                labelText: 'Kondisi Kembali (Opsional)',
                border: OutlineInputBorder(),
                hintText: 'Cth: Baik, Rusak, Hilang sebagian',
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
