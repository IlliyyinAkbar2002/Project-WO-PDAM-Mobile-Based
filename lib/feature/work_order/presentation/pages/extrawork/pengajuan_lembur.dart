import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/profile_view_data.dart';

class PengajuanLemburPage extends StatefulWidget {
  const PengajuanLemburPage({super.key});

  @override
  State<PengajuanLemburPage> createState() => _PengajuanLemburPageState();
}

class _PengajuanLemburPageState extends State<PengajuanLemburPage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _durasiController = TextEditingController(text: '2');
  final TextEditingController _alasanController = TextEditingController();

  final List<String> _workTypes = [
    'Network Repair',
    'Asset Maintenance',
    'Emergency Response',
    'Quality Inspection',
  ];

  final List<String> _teamMembers = ['Illiyyin', 'Fajar', 'Nabila'];

  String? _selectedWorkType;
  DateTime? _tanggalLembur;
  DateTime? _mulaiLembur;

  ({String name, String npp, String jabatan}) _getEmployeeInfo() {
    final user = AuthStorage.getUserSync() ?? <String, dynamic>{};
    final employee =
        (user['employee'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final name =
        (employee['name'] ?? user['name'] ?? '-').toString().trim().isEmpty
            ? '-'
            : (employee['name'] ?? user['name']).toString();

    final rawNpp = employee['employee_id'] ?? employee['nip'] ?? employee['npp'];
    final npp = (rawNpp == null || rawNpp.toString().trim().isEmpty)
        ? '-'
        : rawNpp.toString();

    final jabatan = ProfileViewDataResolver.resolvePositionLabel(user);

    return (name: name, npp: npp, jabatan: jabatan);
  }

  @override
  void dispose() {
    _judulController.dispose();
    _durasiController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _pickTanggalLembur() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLembur ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _tanggalLembur = picked);
    }
  }

  Future<void> _pickMulaiLembur() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _mulaiLembur ?? _tanggalLembur ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_mulaiLembur ?? now),
    );
    if (time == null) return;

    setState(() {
      _mulaiLembur = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Senin, 6 Januari 2025 18:00 WIB';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} $hour:$minute WIB';
  }

  void _submit() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'success',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withValues(alpha: 0.15)),
              ),
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F8EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF16A34A),
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pengajuan Terkirim!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Pengajuan lembur Anda telah berhasil terkirim dan sedang menunggu persetujuan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Kembali ke Beranda'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: const Color(0xFF0F172A),
                  ),
                  const Expanded(
                    child: Text(
                      'Pengajuan Lembur',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    Builder(
                      builder: (context) {
                        final info = _getEmployeeInfo();
                        return _SectionCard(
                          title: 'Informasi Pegawai',
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Nama Pegawai',
                                value: info.name,
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(label: 'NPP', value: info.npp),
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Jabatan',
                                value: info.jabatan,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Detail Lembur',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Judul Pekerjaan'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _judulController,
                            decoration: _inputDecoration(
                              hint: 'Masukan judul pekerjaan...',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const _FieldLabel('Jenis Pekerjaan'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedWorkType,
                            decoration: _inputDecoration(
                              hint: 'Pilih jenis pekerjaan...',
                            ),
                            items: _workTypes
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedWorkType = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          const _FieldLabel('Tanggal Lembur'),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickTanggalLembur,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: _inputDecoration(
                                hint: 'Pilih tanggal lembur...',
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _tanggalLembur == null
                                    ? 'Pilih tanggal lembur...'
                                    : _formatDate(_tanggalLembur),
                                style: TextStyle(
                                  color: _tanggalLembur == null
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Estimasi Waktu Lembur',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickMulaiLembur,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InputDecorator(
                                    decoration: _inputDecoration(
                                      hint: 'Mulai',
                                    ),
                                    child: Text(
                                      _mulaiLembur == null
                                          ? 'Mulai'
                                          : _formatDate(_mulaiLembur),
                                      style: TextStyle(
                                        color: _mulaiLembur == null
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _durasiController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                    hint: '2',
                                    suffixText: 'Jam',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'Selesai: ${_formatDateTime(_mulaiLembur)}',
                              style: const TextStyle(color: Color(0xFF334155)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const _FieldLabel('Anggota Tim'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _teamMembers
                                .map(
                                  (member) => Chip(
                                    label: Text(member),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: () {
                                      setState(() {
                                        _teamMembers.remove(member);
                                      });
                                    },
                                    backgroundColor: const Color(0xFFE2E8F0),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          const _FieldLabel('Alasan Lembur'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _alasanController,
                            maxLines: 4,
                            decoration: _inputDecoration(
                              hint: 'Tuliskan alasan lembur...',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Ajukan Lembur',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  Widget? suffixIcon,
  String? suffixText,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
    suffixIcon: suffixIcon,
    suffixText: suffixText,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2563EB)),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ),
        const Text(':  '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}