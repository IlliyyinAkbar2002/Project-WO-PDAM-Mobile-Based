import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_to_pdf/flutter_to_pdf.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/service/service_locator.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/laporan_workorder_model.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/laporan_workorder_cubit.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

class LaporanWorkorderPage extends StatefulWidget {
  final Map<String, dynamic> payload;

  const LaporanWorkorderPage({super.key, required this.payload});

  @override
  State<LaporanWorkorderPage> createState() => _LaporanWorkorderPageState();
}

class _LaporanWorkorderPageState extends AppStatePage<LaporanWorkorderPage> {
  final ExportDelegate exportDelegate = ExportDelegate();
  late LaporanWorkorderCubit _cubit;
  late String _printTime;
  LaporanReportModel? _report;

  @override
  void initState() {
    super.initState();
    _cubit = sl<LaporanWorkorderCubit>();
    _printTime = DateFormat(
      'dd MMMM yyyy, HH:mm',
      'id_ID',
    ).format(DateTime.now());
    final id = widget.payload['workorder_id'];
    if (id is int) _cubit.loadReport(id);
  }

  // void _submitReport() {
  //   _cubit.submitLaporan(widget.payload);
  // }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // PDF Layout Helpers
  // ─────────────────────────────────────────────

  /// Render section label with left accent bar.
  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          Container(width: 3, height: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  /// Two-column data grid, same style as the HTML preview.
  Widget _dataGrid(List<_FieldItem> fields) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
        children: _buildTableRows(fields),
      ),
    );
  }

  List<TableRow> _buildTableRows(List<_FieldItem> fields) {
    final rows = <TableRow>[];

    for (int i = 0; i < fields.length; i += 2) {
      final isLastRow = (i + 2 >= fields.length);
      final hasRight = (i + 1 < fields.length);

      rows.add(
        TableRow(
          children: [
            _tableCell(fields[i], isLeft: true, isLast: isLastRow),
            hasRight
                ? _tableCell(fields[i + 1], isLeft: false, isLast: isLastRow)
                : _tableCell(null, isLeft: false, isLast: isLastRow),
          ],
        ),
      );
    }

    // Handle full-width (odd leftover) fields
    if (fields.length.isOdd) {
      rows.removeLast();
      rows.add(
        TableRow(
          children: [
            TableCell(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: Colors.grey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fields.last.label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fields.last.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TableCell(child: Container(color: Colors.grey.shade50)),
          ],
        ),
      );
    }

    return rows;
  }

  Widget _tableCell(
    _FieldItem? item, {
    required bool isLeft,
    required bool isLast,
  }) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isLeft ? Colors.grey.shade50 : Colors.white,
          border: Border(
            right: isLeft
                ? BorderSide(color: Colors.grey.shade300, width: 0.5)
                : BorderSide.none,
            bottom: isLast
                ? BorderSide.none
                : BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: item == null
            ? const SizedBox()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Snapshot map/list/string → formatted multiline text block.
  Widget _snapshotBlock(dynamic data) {
    String text = '-';
    if (data is Map) {
      text = data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    } else if (data is List) {
      text = data.map((e) => e.toString()).join('\n');
    } else if (data != null) {
      text = data.toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          height: 1.7,
        ),
      ),
    );
  }

  /// Signature column box.
  Widget _signBox(String role, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            role.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black45,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  String _dash(String? value) =>
      (value == null || value.trim().isEmpty) ? '-' : value.trim();

  String _fmtDate(DateTime? d) =>
      d == null ? '-' : DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(d);

  /// Daftar petugas dengan penanda PIC.
  Widget _memberList(List<LaporanReportMember> members) {
    if (members.isEmpty) return _snapshotBlock('-');
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < members.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: i == members.length - 1
                      ? BorderSide.none
                      : BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dash(members[i].nama),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIP: ${_dash(members[i].nip)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (members[i].isPic)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        'PIC',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPdfDocument(LaporanReportModel report) {
    final nomorLaporan = report.nomorLaporan;
    final workorderId = report.workorderId?.toString() ?? '-';
    final judulLaporan = report.isLembur
        ? 'LAPORAN SELESAI WORK ORDER LEMBUR'
        : 'LAPORAN SELESAI WORK ORDER';
    final tanggal = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());
    final waktu = "${DateFormat('HH:mm', 'id_ID').format(DateTime.now())} WIB";
    final namaPic = _dash(report.pic?.nama);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PDAM PERUMDA SURYA SEMBADA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Kota Surabaya  ·  Portal Work Order  ·  Sistem Manajemen Pekerjaan',
                style: TextStyle(fontSize: 10, color: Colors.black45),
              ),
              const SizedBox(height: 6),
              Container(height: 2, color: Colors.black87),
            ],
          ),

          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Text(
                  judulLaporan,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No. Laporan: $nomorLaporan',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade300, thickness: 0.5),

          _sectionLabel('Identitas Dokumen'),
          _dataGrid([
            _FieldItem('Work Order ID', workorderId),
            _FieldItem('Kode Pengaduan', _dash(report.kodePengaduan)),
            _FieldItem('Tanggal Laporan', tanggal),
            _FieldItem('Status', _dash(report.status)),
            _FieldItem('Waktu Submit', waktu),
          ]),

          // ── LOKASI & WAKTU ──────────────────────────
          _sectionLabel('Lokasi & Waktu Pengerjaan'),
          _dataGrid([
            _FieldItem('Tanggal Mulai', _fmtDate(report.tanggalMulai)),
            _FieldItem('Tanggal Selesai', _fmtDate(report.tanggalSelesai)),
            _FieldItem('Lokasi', _dash(report.lokasi)),
          ]),

          // ── HASIL PEKERJAAN ─────────────────────────
          _sectionLabel('Data Hasil Pekerjaan'),
          _snapshotBlock(_dash(report.hasilAkhir)),

          // ── PENANGGUNG JAWAB & PETUGAS ──────────────
          _sectionLabel('Penanggung Jawab & Petugas'),
          _dataGrid([
            _FieldItem('SPV (Penanggung Jawab)', _dash(report.spvNama)),
            _FieldItem('NIP SPV', _dash(report.spvNip)),
          ]),
          const SizedBox(height: 8),
          _memberList(report.members),

          // ── CATATAN SPV ─────────────────────────────
          _sectionLabel('Catatan SPV'),
          _snapshotBlock(_dash(report.catatanSpv)),

          // ── TANDA TANGAN ────────────────────────────
          _sectionLabel('Tanda Tangan'),
          Row(
            children: [
              Expanded(child: _signBox('Petugas Pelaksana', namaPic)),
              const SizedBox(width: 12),
              Expanded(child: _signBox('Manager EPB', '( ________________ )')),
            ],
          ),

          // ── FOOTER ──────────────────────────────────
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade300, thickness: 0.5),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Dicetak: $_printTime WIB',
                style: const TextStyle(fontSize: 9, color: Colors.black38),
              ),
              const Text(
                'Portal Work Order · PDAM Perumda Surya Sembada',
                style: TextStyle(fontSize: 9, color: Colors.black38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build Page
  // ─────────────────────────────────────────────

  @override
  Widget buildPage(BuildContext context) {
    final isSpv = AuthStorage.getJabatanKodeSync() == 'SPV';

    return BlocProvider(
      create: (_) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Work Order'),
          actions: [
            if (isSpv && _report != null)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export PDF',
                onPressed: () async {
                  try {
                    AppSnackbar.showInfo('Sedang membuat PDF...');

                    final pdfDocument = await exportDelegate
                        .exportToPdfDocument(
                          'laporan_workorder_frame',
                          overrideOptions: ExportOptions(
                            pageFormatOptions: PageFormatOptions.a4(
                              clip: false,
                            ),
                          ),
                        );

                    final outputDirectory =
                        await getApplicationDocumentsDirectory();
                    final file = File(
                      '${outputDirectory.path}/Laporan_WO_${widget.payload['workorder_id'] ?? 'unknown'}.pdf',
                    );
                    await file.writeAsBytes(await pdfDocument.save());

                    if (context.mounted) {
                      // Tampilkan pilihan: Buka atau Bagikan
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'PDF Berhasil Dibuat',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Pilih tindakan:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                leading: const Icon(
                                  Icons.open_in_new,
                                  color: Colors.blueAccent,
                                ),
                                title: const Text('Buka PDF'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await OpenFilex.open(file.path);
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.share,
                                  color: Colors.green,
                                ),
                                title: const Text('Bagikan PDF'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await SharePlus.instance.share(
                                    ShareParams(
                                      files: [XFile(file.path)],
                                      text:
                                          'Laporan Work Order - PDAM Perumda Surya Sembada',
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppSnackbar.showError('Gagal membuat PDF: $e');
                    }
                  }
                },
              ),
          ],
        ),
        body: BlocConsumer<LaporanWorkorderCubit, LaporanWorkorderState>(
          listener: (context, state) {
            if (state is LaporanReportLoaded) {
              setState(() => _report = state.report);
            } else if (state is LaporanReportError) {
              AppSnackbar.showError(state.message);
            }
          },
          builder: (context, state) {
            if (state is LaporanReportError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        final id = widget.payload['workorder_id'];
                        if (id is int) _cubit.loadReport(id);
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            final report = _report;
            if (report == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ExportFrame(
                frameId: 'laporan_workorder_frame',
                exportDelegate: exportDelegate,
                child: _buildPdfDocument(report),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FieldItem {
  final String label;
  final String value;

  _FieldItem(this.label, this.value);
}
