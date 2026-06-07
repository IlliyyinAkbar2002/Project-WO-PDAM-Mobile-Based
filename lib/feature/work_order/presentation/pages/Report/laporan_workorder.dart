import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_to_pdf/flutter_to_pdf.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/service/service_locator.dart';
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

  @override
  void initState() {
    super.initState();
    _cubit = sl<LaporanWorkorderCubit>();
    _printTime = DateFormat(
      'dd MMMM yyyy, HH:mm',
      'id_ID',
    ).format(DateTime.now());
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

  // ─────────────────────────────────────────────
  // Full PDF Document Widget
  // ─────────────────────────────────────────────

  Widget _buildPdfDocument() {
    final p = widget.payload;

    final nomorLaporan = p['nomor_laporan']?.toString() ?? '-';
    final workorderId = p['workorder_id']?.toString() ?? '-';
    final tanggal = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());
    final waktu = "${DateFormat('HH:mm', 'id_ID').format(DateTime.now())} WIB";

    // Petugas snapshot
    final petugasSnap = p['petugas_snapshot'];
    Map<String, dynamic> petugasMap = {};
    if (petugasSnap is Map) {
      petugasMap = Map<String, dynamic>.from(petugasSnap);
    } else if (petugasSnap is List && petugasSnap.isNotEmpty) {
      final first = petugasSnap.first;
      if (first is Map) {
        petugasMap = Map<String, dynamic>.from(first);
      }
    }
    final namaPetugas = petugasMap['nama']?.toString() ?? '-';
    final nip = petugasMap['nip']?.toString() ?? '-';
    final unit =
        petugasMap['unit']?.toString() ??
        petugasMap['departemen']?.toString() ??
        '-';

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

          // ── JUDUL DOKUMEN ────────────────────────────
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                const Text(
                  'LAPORAN SELESAI WORK ORDER',
                  style: TextStyle(
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

          // ── IDENTITAS DOKUMEN ───────────────────────
          _sectionLabel('Identitas Dokumen'),
          _dataGrid([
            _FieldItem('Work Order ID', workorderId),
            _FieldItem('Tanggal Laporan', tanggal),
            _FieldItem('Status', 'Selesai'),
            _FieldItem('Waktu Submit', waktu),
          ]),

          // ── HASIL PEKERJAAN ─────────────────────────
          _sectionLabel('Data Hasil Pekerjaan'),
          _snapshotBlock(p['hasil_akhir_snapshot']),

          // ── INFORMASI PETUGAS ───────────────────────
          _sectionLabel('Informasi Petugas'),
          _dataGrid([
            _FieldItem('Nama Petugas', namaPetugas),
            _FieldItem('NIP', nip),
            _FieldItem('Unit / Bagian', unit),
          ]),

          // ── TANDA TANGAN ────────────────────────────
          _sectionLabel('Tanda Tangan'),
          Row(
            children: [
              Expanded(child: _signBox('Petugas Pelaksana', namaPetugas)),
              const SizedBox(width: 12),
              Expanded(
                child: _signBox('Manager EPB', '( ________________ )'),
              ),
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
    return BlocProvider(
      create: (_) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Work Order'),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export PDF',
              onPressed: () async {
                try {
                  AppSnackbar.showInfo('Sedang membuat PDF...');

                  final pdfDocument = await exportDelegate.exportToPdfDocument(
                    'laporan_workorder_frame',
                    overrideOptions: ExportOptions(
                      pageFormatOptions: PageFormatOptions.a4(clip: false),
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
            if (state is LaporanWorkorderSuccess) {
              AppSnackbar.showSuccess('Laporan berhasil disubmit');
              Navigator.of(context).pop(true);
            } else if (state is LaporanWorkorderFailed) {
              AppSnackbar.showError(state.message);
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // ── Scrollable PDF Preview ─────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ExportFrame(
                      frameId: 'laporan_workorder_frame',
                      exportDelegate: exportDelegate,
                      child: _buildPdfDocument(),
                    ),
                  ),
                ),

                // ── Submit Button ──────────────────────
                // Container(
                //   padding: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withValues(alpha: 0.05),
                //         blurRadius: 10,
                //         offset: const Offset(0, -5),
                //       ),
                //     ],
                //   ),
                //   child: SizedBox(
                //     width: double.infinity,
                //     height: 48,
                //     child: ElevatedButton(
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: Colors.blueAccent,
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(8),
                //         ),
                //       ),
                //       onPressed: state is LaporanWorkorderLoading
                //           ? null
                //           : _submitReport,
                //       child: state is LaporanWorkorderLoading
                //           ? const SizedBox(
                //               height: 24,
                //               width: 24,
                //               child: CircularProgressIndicator(
                //                 color: Colors.white,
                //                 strokeWidth: 2.5,
                //               ),
                //             )
                //           : const Text(
                //               'Submit Laporan',
                //               style: TextStyle(
                //                 fontSize: 16,
                //                 fontWeight: FontWeight.bold,
                //                 color: Colors.white,
                //               ),
                //             ),
                //     ),
                //   ),
                // ),
              ],
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
